create unlogged table payments (
    correlation_id char(36) unique,
    amount decimal not null,
    payment_processor int not null,
    inserted_at timestamp not null
);

create index idx_payments_inserted_at on payments(inserted_at);

create unlogged table payment_processor_priority (
    payment_processor_1_failing char(1) not null,
    payment_processor_1_min_response_time int not null,
    payment_processor_1_updated_at timestamp not null,
    payment_processor_2_failing char(1) not null,
    payment_processor_2_min_response_time int not null,
    payment_processor_2_updated_at timestamp not null,
    updated_at timestamp not null
);

create unlogged table payments_retry (
    correlation_id char(36) unique primary key,
    amount decimal not null
);