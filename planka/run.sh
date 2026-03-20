#!/usr/bin/env bashio
set -euo pipefail

ENV_FILE="/config/.env"
PG_DATA="/data/postgres"
PG_SOCKET="/tmp/postgres"

bashio::log.info "Initialisation Planka"

# ===============================
# INIT POSTGRES DATA DIR
# ===============================
if [[ ! -d "$PG_DATA" ]]; then
    bashio::log.info "Initialisation PostgreSQL"
    mkdir -p "$PG_DATA"
    chown postgres:postgres "$PG_DATA"
    sudo -u postgres initdb -D "$PG_DATA" -E UTF8
fi

# ===============================
# START POSTGRES
# ===============================
bashio::log.info "Démarrage PostgreSQL"
mkdir -p "$PG_SOCKET"
chown postgres:postgres "$PG_SOCKET"

# Start PostgreSQL in background
sudo -u postgres pg_ctl -D "$PG_DATA" -l "$PG_DATA/postgres.log" -o "-k $PG_SOCKET -c listen_addresses=localhost" start

# Wait for PostgreSQL to be ready
for i in {1..30}; do
    if sudo -u postgres pg_isready -q -h "$PG_SOCKET"; then
        break
    fi
    sleep 1
done

# Create database and user
DB_USER="$(bashio::config 'DATABASE.db_user')"
DB_PASSWORD="$(bashio::config 'DATABASE.db_password')"
DB_NAME="$(bashio::config 'DATABASE.db_name')"

sudo -u postgres psql -h "$PG_SOCKET" -d postgres <<-EOF
CREATE USER "$DB_USER" WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE "$DB_NAME" OWNER "$DB_USER";
GRANT ALL PRIVILEGES ON DATABASE "$DB_NAME" TO "$DB_USER";
EOF 2>/dev/null || true

# ===============================
# SECRET (jamais modifié)
# ===============================
if [[ ! -f "$ENV_FILE" ]] || ! grep -q "^SECRET_KEY=" "$ENV_FILE"; then
    bashio::log.info "Génération du SECRET"
    SECRET="$(openssl rand -hex 64)"
    echo "SECRET_KEY=${SECRET}" >> "$ENV_FILE"
fi

# ===============================
# DATABASE_URL (avec socket local)
# ===============================
NEW_DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"

DB_CHANGED=false

if grep -q "^DATABASE_URL=" "$ENV_FILE" 2>/dev/null; then
    CURRENT_DATABASE_URL="$(grep "^DATABASE_URL=" "$ENV_FILE" | cut -d'=' -f2-)"
    if [[ "$CURRENT_DATABASE_URL" != "$NEW_DATABASE_URL" ]]; then
        bashio::log.warning "DATABASE_URL modifiée"
        sed -i "s|^DATABASE_URL=.*|DATABASE_URL=${NEW_DATABASE_URL}|" "$ENV_FILE"
        DB_CHANGED=true
    else
        bashio::log.info "DATABASE_URL inchangée"
    fi
else
    bashio::log.info "Ajout DATABASE_URL"
    echo "DATABASE_URL=${NEW_DATABASE_URL}" >> "$ENV_FILE"
    DB_CHANGED=true
fi

# ===============================
# BASE_URL
# ===============================
BASE_URL="http://localhost:1338"

if grep -q "^BASE_URL=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^BASE_URL=.*|BASE_URL=${BASE_URL}|" "$ENV_FILE"
else
    echo "BASE_URL=${BASE_URL}" >> "$ENV_FILE"
fi

# ===============================
# ADMIN (premier démarrage uniquement)
# ===============================
if ! grep -q "^DEFAULT_ADMIN_EMAIL=" "$ENV_FILE" 2>/dev/null; then
    ADMIN_EMAIL="$(bashio::config 'ADMIN.email')"
    ADMIN_PASSWORD="$(bashio::config 'ADMIN.password')"
    ADMIN_NAME="$(bashio::config 'ADMIN.name')"

    bashio::log.info "Création admin initial"
    echo "DEFAULT_ADMIN_EMAIL=${ADMIN_EMAIL}" >> "$ENV_FILE"
    echo "DEFAULT_ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> "$ENV_FILE"
    echo "DEFAULT_ADMIN_NAME=${ADMIN_NAME}" >> "$ENV_FILE"
fi

# ===============================
# PERMISSIONS
# ===============================
cd /opt/planka
cp $ENV_FILE ./
chmod 600 "$ENV_FILE"
chmod 600 "./.env"

# ===============================
# DB INIT SI NECESSAIRE
# ===============================
if [[ "$DB_CHANGED" == "true" ]]; then
    bashio::log.warning "Initialisation / migration base de données"
    npm run db:init
fi

# ===============================
# START PLANKA
# ===============================
bashio::log.info "Démarrage Planka"

# Function to cleanup on exit
cleanup() {
    bashio::log.info "Arrêt PostgreSQL"
    sudo -u postgres pg_ctl -D "$PG_DATA" stop
}
trap cleanup EXIT

exec npm start --production
