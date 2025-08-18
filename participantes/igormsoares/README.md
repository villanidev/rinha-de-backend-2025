# Rinha de Backend 2025

Um sistema de encaminhamento de pagamentos para a minha solução da [Rinha de Backend 2025](https://github.com/zanfranceschi/rinha-de-backend-2025).

## Tecnologias

- Go
- Nginx
- Redis

## Serviços

- `payment-proxy`: responsável por processar as requisições que chegam (`POST /payments` e `GET /payments-summary`).
- `nginx`: responsável por balancear as requisições entre as 2 instâncias de `payment-proxy`.
- `redis`: utilizado como fila para os pagamentos a serem encaminhados para os `payment-processor` e também como storage para registrar o total de requisições e o valor total processados por cada `payment-processor`.

### Executar

_Necessário que a rede docker `payment-processor` já tenha sido criada._

```bash
docker compose up -d
```

## Código Fonte

[github.com/igorMSoares/rinha-backend-2025](https://github.com/igorMSoares/rinha-backend-2025)
