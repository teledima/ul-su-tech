CREATE DATABASE IF NOT EXISTS mart;

CREATE TABLE IF NOT EXISTS mart.dim_city
(
    gc_id            Int64,
    city_name        String,
    region_name      String,
    full_name_local  String,
    latitude         Float64,
    longitude        Float64,
    computed_at      DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY gc_id;

CREATE TABLE IF NOT EXISTS mart.route_market_corridor
(
    month_start          Date,
    loading_city_gcid    Int64,
    loading_city_name    LowCardinality(String),
    loading_region       LowCardinality(String),
    unloading_city_gcid  Int64,
    unloading_city_name  LowCardinality(String),
    unloading_region     LowCardinality(String),

    body_type_id         Int,
    body_type            LowCardinality(String),

    weight_category      LowCardinality(String),
    volume_category      LowCardinality(String),

    -- коридор за рейс, руб./рейс
    p25_trip             Double Precision,
    p50_trip             Double Precision,
    p75_trip             Double Precision,
    avg_trip             Double Precision,
    -- коридор за километр, руб./км
    p25_km               Double Precision,
    p50_km               Double Precision,
    p75_km               Double Precision,
    -- Data Trust
    -- изменение p50 за рейс в процентах по сравнению с прошлым месяцем/годом
    mom_pct              Nullable(Double Precision),
    yoy_pct              Nullable(Double Precision),
    trips_count          UInt32,
    carriers_count       UInt32,
    cv_rate              Nullable(Double Precision),
    reliability_level    LowCardinality(String),
    computed_at          DateTime
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(month_start)
ORDER BY (loading_city_gcid, unloading_city_gcid, body_type_id, weight_category, month_start);

CREATE TABLE IF NOT EXISTS mart.ml_price_predictions
(
    price_id             Int64,
    model_name           LowCardinality(String),
    predicted_price_rub  Double Precision,
    actual_price_rub     Nullable(Double Precision),
    abs_error_rub        Nullable(Float64),
    ape_pct              Nullable(Float64),
    computed_at          DateTime
)
ENGINE = ReplacingMergeTree(computed_at)
PARTITION BY toYYYYMM(computed_at)
ORDER BY (model_name, price_id);
