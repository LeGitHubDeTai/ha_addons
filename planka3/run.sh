#!/usr/bin/env bashio
set -euo pipefail

ENV_FILE="/data/.env"

bashio::log.info "Initialisation Planka"

# ===============================
# SECRET
# ===============================
if [[ ! -f "$ENV_FILE" ]] || ! grep -q "^SECRET=" "$ENV_FILE"; then
    bashio::log.info "Génération du SECRET"
    SECRET="$(openssl rand -hex 64)"
    echo "SECRET=${SECRET}" >> "$ENV_FILE"
else
    bashio::log.info "SECRET déjà présent"
fi

# ===============================
# DATABASE
# ===============================
if ! grep -q "^DATABASE_URL=" "$ENV_FILE"; then
    bashio::log.info "Configuration DATABASE_URL"

    DB_HOST="$(bashio::config 'DATABASE.db_host')"
    DB_PORT="$(bashio::config 'DATABASE.db_port')"
    DB_USER="$(bashio::config 'DATABASE.db_user')"
    DB_PASSWORD="$(bashio::config 'DATABASE.db_password')"
    DB_NAME="$(bashio::config 'DATABASE.db_name')"

    DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

    echo "DATABASE_URL=${DATABASE_URL}" >> "$ENV_FILE"
    exec npm run db:init
else
    bashio::log.info "DATABASE_URL déjà présente"
fi

# ===============================
# BASE_URL
# ===============================
if ! grep -q "^BASE_URL=" "$ENV_FILE"; then
    bashio::log.info "Configuration BASE_URL (Ingress)"
    echo "BASE_URL=http://localhost:1337" >> "$ENV_FILE"
else
    bashio::log.info "BASE_URL déjà présent"
fi

# ===============================
# PERMISSIONS
# ===============================
chmod 600 "$ENV_FILE"

# ===============================
# START PLANKA
# ===============================
cd /opt/planka

bashio::log.info "Démarrage Planka"
exec npm start --prod
