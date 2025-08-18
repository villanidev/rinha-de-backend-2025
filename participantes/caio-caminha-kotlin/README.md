# Rinha de Backend 2025 - Submissão Kotlin e Spring

Aplicação em Kotlin usando Spring Native com GraalVM para gerar um executavel nativo

Como servlet container foi usado o Undertow, e para realizar requisições para o payment-processor foi utilizado o WebFlux.

O padrão para processar os pagamentos foi um worker pool, utlizando o Channel como queue e criando uma coroutine (usando launch builder) para cada worker.

Para cada pagamento dentro do worker pool eventualmente é criada uma nova coroutine usando o async builder que retorna um Deferred. Porém como cada worker processa um pagamento por vez, o processamento de cada pagamento dentro de um worker é sequencial.

Os pagamentos estão sendo salvos em memória numa ConcurrentLinkedQueue. Para agilizar o retorno do payments-summary quando os params from e to forem null, mantendo o resultado total em memória para default e fallback para evitar fazer um traversing em toda a lista.

Como cada instancia gerencia sua propria ConcurrentLinkedQueue, preciso fazer uma requisição http para a outra instancia para mergear os valores e retornar, o que adiciona uma camada de complexidade e acaba aumentando o tempo de resposta.

