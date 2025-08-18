# API Payment Process - Wildemberg Sales

Este projeto é uma **API de pagamentos** desenvolvida em **.NET 8**, projetada para participar da **Rinha de Backend 2025**.  
A aplicação implementa processamento de pagamentos com suporte a **fallback**, utiliza **PostgreSQL** como banco de dados e faz balanceamento de carga com **Nginx**.

---

## 🚀 Tecnologias Utilizadas
- **.NET 8 / ASP.NET Core** (API REST)
- **PostgreSQL 17 (alpine)**
- **Nginx** (reverse proxy e load balancing)
- **Docker Compose** (orquestração de containers)

---

## 📂 Estrutura Lógica do Projeto
- `API` → Projeto principal desenvolvido com o ASP.NET para compilação AOT que recebe todas as chamadas realizadas pelo usuário.
- `WorkerPayment` → Background service com implementação de **Channel** para processamento assíncrono dos pagametos, efetuando requisição e salvamento dos dados.
- `WorkerPersistenceFail` → Background Service com implementação de **Channel** para caso o processo principal não consiga salvar após a requisição bem sucessida para a API externa, ele envia para esse serviço que fica focado na persistência do dado.

## 📂 Estrutura do Docker Compose
- `api1` e `api2` → instâncias da API  
- `db` → banco de dados PostgreSQL  
- `nginx` → load balancer e proxy reverso  
- `docker-compose.yml` → definição de toda a stack  

---

## 🗄️ Banco de Dados
O schema é criado via DDL já internamente inserido na imagem da API:

```sql
CREATE TABLE IF NOT EXISTS "Payments" (
    "CorrelationId" uuid NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp NOT NULL,
    "IsFallback" boolean NOT NULL,
    CONSTRAINT "PK_Payments" PRIMARY KEY ("CorrelationId")
);