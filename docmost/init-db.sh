#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"

echo "Initializing PostgreSQL..."

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -q; do
    sleep 1
done

DB_PASSWORD="$(jq --raw-output '.db_password // empty' "$CONFIG_PATH")"

# Check if database exists
if ! psql -h localhost -U postgres -lqt | cut -d \| -f 1 | grep -qw docmost; then
    echo "Creating database and user..."
    psql -h localhost -U postgres <<-EOSQL
        CREATE USER docmost WITH PASSWORD '${DB_PASSWORD}';
        CREATE DATABASE docmost OWNER docmost;
        GRANT ALL PRIVILEGES ON DATABASE docmost TO docmost;
EOSQL
    echo "Database created successfully."
else
    echo "Database already exists."
fi
