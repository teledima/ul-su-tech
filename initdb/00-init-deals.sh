#!/bin/sh
set -eu

: "${POSTGRES_USER:?POSTGRES_USER is not set}"
: "${POSTGRES_DB:?POSTGRES_DB is not set}"

N_PRICES="${N_PRICES:-300000}"

echo "Creating Airflow role and database if they do not exist"

role_exists=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'airflow'")
if [ "$role_exists" != "1" ]; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE ROLE airflow LOGIN PASSWORD 'airflow';"
fi

db_exists=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname = 'airflow'")
if [ "$db_exists" != "1" ]; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE airflow OWNER airflow;"
fi

echo "Applying schema.sql to database $POSTGRES_DB"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /sql-init/schema.sql

echo "Loading synthetic.sql into database $POSTGRES_DB with n_prices=$N_PRICES"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -v n_prices="$N_PRICES" -f /sql-init/synthetic.sql

echo "Creating initialization marker"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS data_init_marker (
  id int PRIMARY KEY,
  initialized_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO data_init_marker (id)
VALUES (1)
ON CONFLICT (id) DO UPDATE SET initialized_at = EXCLUDED.initialized_at;
SQL

echo "PostgreSQL initialization completed"
