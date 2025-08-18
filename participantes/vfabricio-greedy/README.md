# Rinha de Backend 2025

Minha submissão à Rinha de Backend 2025.

# Filosofia

Minha intenção é escrever um código otimizado, mas que não seja extremamente "overfittado" às condições da Rinha.
É possível (embora na minha opinião não no espírito da Rinha) escrever código que atinge uma pontuação alta, mas que faz suposições frágeis, específicas de como os testes são conduzidos.
Por exemplo, fazer um fire e forget com o "load balancer" retornando 200 incondicionalmente.
Ou "persistir" tudo em memória apenas.
Eu tentei então, escrever um código relativamente próximo de algo que eu ficaria confortável colocando em produção:
- As respostas do load balancer são respostas reais geradas pelos gateways depois de terem confirmado com os pagamentos estão enfileirados;
- O load balancer _realmente_ balanceia a carga. Se qualquer um dos gateways morrer, ele consegue redirecionar as próximas requisições ao outro, ao invés de perder metade delas, por exemplo. Com mais tempo eu teria implementado reconexões dinâmicas para mais robustez.
- A fila é relativamente persistente. Caso ela seja reiniciada, a _maioria_ dos pegamentos estarão salvos. A garantia não éabsoluta, porque pode acontecer de os pedidos enfileirados nos últimos segundos serem perdidos. Mas já é infinitamente mais robusto que deixar todos em memória. Num sistema real provavelmente só deveríamos enviar a confirmação ao cliente depois de um fsync garantindo que todos os bytes estão fisicamente no disco.
- Os resultados dos pagamentos processados são armazenados em disco.

# Versões

Fiz algumas submissões diferentes. Como não é necessariamente claro qual é superior, vou deixar todas competirem. Elas podem ser identificadas pelas seguintes tags no repositório:

- [vfabricio-greedy](https://github.com/zanfranceschi/rinha-de-backend-2025/tree/main/participantes/vfabricio-greedy) (v1): https://github.com/VFabricio/rinha_2025/tree/v0.1
- [vfabricio-custom-queue](https://github.com/zanfranceschi/rinha-de-backend-2025/tree/main/participantes/vfabricio-custom-queue) (v1): https://github.com/VFabricio/rinha_2025/tree/v0.2
- [vfabricio-uds-greedy](https://github.com/zanfranceschi/rinha-de-backend-2025/tree/main/participantes/vfabricio-custom-queue) (v1): https://github.com/VFabricio/rinha_2025/tree/v0.3
- [vfabricio-uds-quick](https://github.com/zanfranceschi/rinha-de-backend-2025/tree/main/participantes/vfabricio-custom-queue) (v4): https://github.com/VFabricio/rinha_2025/tree/v0.3 (é o mesmo código, só muda uma variável de ambiente no docker-compose.yml)

Todas elas tem os mesmos compoenentes básicos:
- load balancer: recebe as requisições HTTP do mundo externo e as encaminha para os gateways. Escrito do zero.
- gateways: recebe as requisições encaminhadas pelo load balancer, armazena os detalhes do pagamento na fila e reporta sucesso.
- queue: uma fila FIFO contendo os pagamentos a serem processados
- worker: remove pagamentos da fila e os encaminha aos payment processors. Caso receba um erro, o pagamento é re-enfileirado para retentativa.

O gateway (são duas cópias idênticas) e o worker mudam pouco de uma versão para a outra. Mas no load balancer e queue tentei algumas estratégias diferentes.

Na v1 o load balancer funciona como um servidor HTTP normal, parseando as requisições da stream TCP e encaminhando aos gateways.
A partir da v2 ele usa uma abordagem de muito mais baixo nível, onde assim que iniciado uma pool grande de conexões para os gateways é aberta e, cada vez que uma nova conexão com um cliente é estabelecida, ele usa a system call splice para amarrá-la a uma das conexões com um gateway. Isso faz com que à medida que os dados cheguem do cliente eles sejam copiados do buffer de um socket para o do outro em kernel space, sem precisar passar pelo processo do load balancer em si.
Apesar de ser intuitivamente uma abordagem muito mais rápida, por evitar cópias e o parseamento desnecessário das requisições pelo load balancer, a performance ficou a mesma em ambas as abordagens.

Na v1 a fila era um valkey.
A partir v2 passei a usar uma servidor escrito do zero em Rust.
Isso passou por definir um wire protocol para a comunicação pela rede do servidor da fila com os gateways e workers.
Aqui os ganhos de performance foram marginais.
Mas esta queue é escrita de forma bastante simplória e com certeza tem oportunidades grandes de otimização.

A partir da v3 os componentes são os mesmos mas, ao invés de usarem conexões TCP toda a comunicação entre meus componentes (isto é, tudo exceto as conexões dos clientes com o load balancer e do worker com os payment providers) são feitas através de Unix domain sockets.

# Estratégias de roteamento

O twist desta versão da Rinha está nos dois processadores de pagamentos.
Para além das questões de infraestrutura genéricas, a pergunta é: qual é a estratégia ótima para distribuir os pagamentos entre os processadores.

O insight é que, se fosse um sistema real, a escolha seria determinada pelo tempo aceitável para processar os pagamentos após enfileirados.
Se não houver nenhum requisito duro sobre isso, nunca há motivo para usar o fallback!
Contanto que possamos esperar, sempre vale a pena esperar o default estar saudável e sempre mandar tudo para ele.

Se isso é viável na Rinha vai depender de como exatamente os steps vão estar configurados no teste final.
No exemplo que temos para o desenvolvimento, há um tempo razoável entre o default voltar a estar saudável e os resultados finais serem coletados.
Então, o que a maioria das submissões que tenho visto está fazendo é rotear tudo par ele incondicionalmente.

Mas, se nos testes finais, o default não estiver saudável por tempo suficiente para drenar a fila, podemos perder pagamentos.
Nesse caso pode ser mais rentável mandar pelo menos alguns dos pagamentos para o fallback.

Levando isso em consideração, estou dividindo minhas submissões entre duas estratégias:
- A v1 e a v3 usam a estratégia _greedy_: mandar tudo para o default e rezar!
- A v2 e a v4 usam a estratégia _quick_: aqui os workers usam os health checks e as respostas retornadas pelos payment providers (se há erros ou timeouts) para monitorar a saúde destes. Com base nisso eles tentam dividir os pagamentos entre eles tentando maximizar throughput e o tempo em que os pedidos ficam enfileirados. Esta estratégia é mais necessariamente mais cara, em termos da porcentagem paga em taxas, mas mais segura, no sentido de que a probabilidade de perda de pagamentos no final do teste é menor.
