-- init.sql
CREATE TABLE IF NOT EXISTS "Payments" (
    "CorrelationId" uuid NOT NULL,
    "Amount" decimal(18,2) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "IsFallback" boolean NOT NULL,
    CONSTRAINT "PK_Payments" PRIMARY KEY ("CorrelationId")
);

COMMENT ON TABLE "Payments" IS 'Armazena os registros de transações de pagamento processadas.';