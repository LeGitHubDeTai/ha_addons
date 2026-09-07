#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"
PGDATA="/var/lib/postgresql/data"

# ===============================
# Initialize PostgreSQL if needed
# ===============================
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Running initdb..."
    su -s /bin/bash postgres -c "/usr/lib/postgresql/16/bin/initdb -D $PGDATA"
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" "$PGDATA/postgresql.conf"
    echo "PostgreSQL initialized."
fi

# ===============================
# Start PostgreSQL in background
# ===============================
echo "Starting PostgreSQL..."
su -s /bin/bash postgres -c "/usr/lib/postgresql/16/bin/pg_ctl -D $PGDATA -o '-c config_file=$PGDATA/postgresql.conf' start -w"

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -U postgres -q; do
    sleep 1
done
echo "PostgreSQL is ready."

# ===============================
# Create database and user
# ===============================
DB_PASSWORD="$(jq --raw-output '.db_password // empty' "$CONFIG_PATH")"

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

# ===============================
# Wait for Redis
# ===============================
echo "Waiting for Redis..."
until redis-cli -h localhost -p 6379 ping | grep -q PONG; do
    sleep 1
done
echo "Redis is ready."

# ===============================
# Read configuration
# ===============================
APP_SECRET="$(jq --raw-output '.app_secret // empty' "$CONFIG_PATH")"

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

# ===============================
# Set environment variables
# ===============================
export APP_URL="http://localhost:3000"
export APP_SECRET="${APP_SECRET}"
export DATABASE_URL="postgresql://docmost:${DB_PASSWORD}@localhost:5432/docmost"
export REDIS_URL="redis://localhost:6379"
export PORT=3000
export STORAGE_DRIVER=local
export DISABLE_TELEMETRY=true

# ===============================
# Start Docmost
# ===============================
echo "Starting Docmost..."
cd /app
exec pnpm start
