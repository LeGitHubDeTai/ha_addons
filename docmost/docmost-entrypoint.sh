#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until pg_isready -h localhost -p 5432 -U docmost -q; do
    sleep 1
done
echo "PostgreSQL is ready."

# Wait for Redis to be ready
echo "Waiting for Redis..."
until redis-cli -h localhost -p 6379 ping | grep -q PONG; do
    sleep 1
done
echo "Redis is ready."

# Read configuration
APP_SECRET="$(jq --raw-output '.app_secret // empty' "$CONFIG_PATH")"
DB_PASSWORD="$(jq --raw-output '.db_password // empty' "$CONFIG_PATH")"

# Generate APP_SECRET if not provided
if [ -z "$APP_SECRET" ]; then
    SECRET_FILE="/data/docmost/.app_secret"
    if [ -f "$SECRET_FILE" ]; then
        APP_SECRET="$(cat "$SECRET_FILE")"
    else
        APP_SECRET="$(openssl rand -hex 32)"
        echo "$APP_SECRET" > "$SECRET_FILE"
    fi
fi

# Set environment variables
export APP_URL="http://localhost:5200"
export APP_SECRET="${APP_SECRET}"
export DATABASE_URL="postgresql://docmost:${DB_PASSWORD}@localhost:5432/docmost"
export REDIS_URL="redis://localhost:6379"
export PORT=3000
export STORAGE_DRIVER=local
export DISABLE_TELEMETRY=true

echo "Starting Docmost..."
cd /opt/docmost
exec node dist/server.js
