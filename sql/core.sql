CREATE SCHEMA IF NOT EXISTS core;

CREATE TABLE IF NOT EXISTS core.dim_city (
    gc_id            bigint PRIMARY KEY,
    source_id        bigint,
    city_name        text,
    region           text,
    full_name_local  text,
    latitude         double precision,
    longitude        double precision,
    loaded_at        timestamp NOT NULL
);

CREATE TABLE IF NOT EXISTS core.dim_body_type (
    id           bigint       PRIMARY KEY,
    name         varchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS core.fact_prices(
    id                    bigint PRIMARY KEY,

    loading_city_id       bigint NOT NULL REFERENCES core.dim_city(gc_id),
    unloading_city_id     bigint NOT NULL REFERENCES core.dim_city(gc_id),
    primary_body_type     bigint NOT NULL REFERENCES core.dim_body_type(id),

    distance              double precision NOT NULL,
    total_weight          double precision NOT NULL,
    total_volume          double precision NOT NULL,
    weight_category       varchar(4) NOT NULL,
    volume_category       varchar(4) NOT NULL,

    price                 double precision NOT NULL,
    price_rub             double precision NOT NULL,
    price_rub_per_km      double precision NOT NULL,
    exchange_rate         double precision NOT NULL,
    currency_code         varchar(3)       NOT NULL,
    nearest_rate_date     date,

    price_type            smallint NOT NULL,
    outlier_mark          boolean NOT NULL,

    loading_date          date      NOT NULL,
    created_at            timestamp NOT NULL,
    loaded_at             timestamp NOT NULL

    CONSTRAINT chk_fact_prices_distance_positive  CHECK (distance > 0),
    CONSTRAINT chk_fact_prices_price_rub_positive CHECK (price_rub > 0),
    CONSTRAINT chk_fact_prices_weight_positive    CHECK (total_weight > 0),
    CONSTRAINT chk_fact_prices_volume_positive    CHECK (total_volume > 0)
);

CREATE TABLE IF NOT EXISTS core.bridge_price_body_types(
    id           bigint PRIMARY KEY,
    price_id     bigint NOT NULL REFERENCES core.fact_prices(id),
    body_type_id bigint NOT NULL REFERENCES core.dim_body_type(id),
    UNIQUE (price_id, body_type_id)
);

CREATE TABLE IF NOT EXISTS core.bridge_price_dates(
    id         bigint PRIMARY KEY,
    price_id   bigint NOT NULL REFERENCES core.fact_prices(id),
    price_date date   NOT NULL,
    UNIQUE (price_id, price_date)
);

CREATE TABLE IF NOT EXISTS core.dq_quarantine_prices(
    id        bigserial primary key,
    price_id  bigint not null references prices(id),
    code      varchar not null,
    meta      jsonb,
    loaded_at timestamp
);