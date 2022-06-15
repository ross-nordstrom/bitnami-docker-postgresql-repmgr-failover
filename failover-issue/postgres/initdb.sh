#!/bin/bash

pg_roles=$(PGPASSWORD=${POSTGRES_PASSWORD} psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres --command "SELECT rolname FROM pg_roles;")
if [[ $pg_roles == *"appuser"* ]]; then
  echo "Already has a appuser db/user"
else
  echo "No appuser db/user. Creating..."
  PGPASSWORD=$POSTGRES_PASSWORD psql -v ON_ERROR_STOP=1 -h 127.0.0.1 --username postgres --dbname postgres <<-EOSQL
    CREATE USER appuser WITH PASSWORD 'pwd';
    CREATE DATABASE appdb;
    GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
EOSQL
fi

echo "Populate app table"
PGPASSWORD="pwd" psql -v ON_ERROR_STOP=1 -U appuser -d appdb <<-EOSQL
  CREATE TABLE IF NOT EXISTS foo (value INT);
  INSERT INTO foo(value) VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9);
EOSQL
