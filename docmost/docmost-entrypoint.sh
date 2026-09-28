#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"
PGDATA="/var/lib/postgresql/data"
PG_BIN="/usr/lib/postgresql/16/bin"

# ===============================
# Read database configuration
# ===============================
DB_HOST="$(jq --raw-output '.DATABASE.db_host // empty' "$CONFIG_PATH")"
DB_PORT="$(jq --raw-output '.DATABASE.db_port // empty' "$CONFIG_PATH")"
DB_NAME="$(jq --raw-output '.DATABASE.db_name // empty' "$CONFIG_PATH")"
DB_USER="$(jq --raw-output '.DATABASE.db_user // empty' "$CONFIG_PATH")"
DB_PASSWORD="$(jq --raw-output '.DATABASE.db_password // empty' "$CONFIG_PATH")"

# Fallback for configurations saved before the DATABASE section existed
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD="$(jq --raw-output '.db_password // empty' "$CONFIG_PATH")"
fi

if [ -z "$DB_HOST" ]; then
    DB_HOST="localhost"
fi
if [ -z "$DB_PORT" ]; then
    DB_PORT="5432"
fi
if [ -z "$DB_NAME" ]; then
    DB_NAME="docmost"
fi
if [ -z "$DB_USER" ]; then
    DB_USER="docmost"
fi

# Escape single quotes for SQL literals
SQL_PASSWORD="${DB_PASSWORD//\'/\'\'}"

case "$DB_HOST" in
    ""|localhost|127.0.0.1|::1)
        USE_LOCAL_PG="true"
        ;;
    *)
        USE_LOCAL_PG="false"
        ;;
esac

# ===============================
# PostgreSQL: bundled or external
# ===============================
if [ "$USE_LOCAL_PG" = "true" ]; then
    if [ ! -f "$PGDATA/PG_VERSION" ]; then
        echo "Running initdb..."
        su -s /bin/bash postgres -c "$PG_BIN/initdb -D $PGDATA"
        sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" "$PGDATA/postgresql.conf"
        echo "PostgreSQL initialized."
    fi

    echo "Starting PostgreSQL..."
    su -s /bin/bash postgres -c "$PG_BIN/pg_ctl -D $PGDATA -o '-c config_file=$PGDATA/postgresql.conf -c port=$DB_PORT' start -w"

    until pg_isready -h localhost -p "$DB_PORT" -U postgres -q; do
        sleep 1
    done
    echo "PostgreSQL is ready."

    echo "Syncing role and database..."
    if psql -h localhost -p "$DB_PORT" -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1; then
        psql -h localhost -p "$DB_PORT" -U postgres -c "ALTER ROLE \"${DB_USER}\" WITH PASSWORD '${SQL_PASSWORD}';"
    else
        psql -h localhost -p "$DB_PORT" -U postgres -c "CREATE ROLE \"${DB_USER}\" WITH LOGIN PASSWORD '${SQL_PASSWORD}';"
    fi

    if psql -h localhost -p "$DB_PORT" -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
        psql -h localhost -p "$DB_PORT" -U postgres -c "ALTER DATABASE \"${DB_NAME}\" OWNER TO \"${DB_USER}\";" || true
    else
        psql -h localhost -p "$DB_PORT" -U postgres -c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_USER}\";"
    fi

    psql -h localhost -p "$DB_PORT" -U postgres -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE \"${DB_NAME}\" TO \"${DB_USER}\";" || true
    psql -h localhost -p "$DB_PORT" -U postgres -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO \"${DB_USER}\";" || true
else
    echo "Using external PostgreSQL at ${DB_HOST}:${DB_PORT}..."
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi

    tries=0
    until pg_isready -h "$DB_HOST" -p "$DB_PORT" -q; do
        tries=$((tries + 1))
        if [ "$tries" -ge 60 ]; then
            echo "ERROR: PostgreSQL at ${DB_HOST}:${DB_PORT} is unreachable." >&2
            exit 1
        fi
        sleep 1
    done
    echo "PostgreSQL is reachable."

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" 2>/dev/null | grep -q 1; then
        echo "Database ${DB_NAME} already exists."
    else
        echo "Creating database ${DB_NAME}..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_USER}\";" \
            || echo "Could not create ${DB_NAME} (already exists or missing rights), continuing."
    fi
    unset PGPASSWORD
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
DB_USER_URL="$(jq -rn --arg v "$DB_USER" '$v|@uri')"
DB_PASSWORD_URL="$(jq -rn --arg v "$DB_PASSWORD" '$v|@uri')"

export APP_URL="http://localhost:3000"
export APP_SECRET="${APP_SECRET}"
export DATABASE_URL="postgresql://${DB_USER_URL}:${DB_PASSWORD_URL}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
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
