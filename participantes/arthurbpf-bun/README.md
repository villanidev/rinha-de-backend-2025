# Rinha de Backend 2025 - Arthur Fernandes

## Informações do Projeto

| Campo | Valor |
| --- | --- |
| Nome | Arthur Fernandes |
| Repositório Worker | [arthurbpf/rinha-de-backend-2025-worker](https://github.com/arthurbpf/rinha-de-backend-2025-worker) |
| Repositório API | [arthurbpf/rinha-de-backend-2025-api](https://github.com/arthurbpf/rinha-de-backend-2025-api)|
| Linguagem | TypeScript |
| Banco de dados | SQLite |
| Mensageria | pqueue |
| Load Balancer | Nginx |

## Arquitetura

A arquitetura da aplicação é composta pelos seguintes serviços:

- **`lb` (Load Balancer):** Serviço Nginx responsável por distribuir as requisições entre as instâncias da API.
- **`api1` e `api2` (API):** Instâncias da API da aplicação, que recebem as requisições do load balancer.
- **`worker`:** Serviço responsável por processar os pagamentos em segundo plano.

O fluxo da aplicação é o seguinte:

1. O cliente envia uma requisição para a porta `9999`, que é a porta do load balancer.
2. O load balancer distribui a requisição para uma das instâncias da API (`api1` ou `api2`), utilizando o algoritmo `least_conn`.
3. A API envia a requisição de processamento de pagamento para o `worker`.
4. O `worker` processa o pagamento e se comunica com os processadores de pagamento externos.

## Como executar

Para executar a aplicação, basta executar o seguinte comando:

```bash
docker-compose up -d
```
