#!/usr/bin/env bashio
set -euo pipefail

ENV_FILE="/config/.env"

bashio::log.info "Initialisation Planka"

# ===============================
# SECRET (jamais modifié)
# ===============================
if [[ ! -f "$ENV_FILE" ]] || ! grep -q "^SECRET_KEY=" "$ENV_FILE"; then
    bashio::log.info "Génération du SECRET"
    SECRET="$(openssl rand -hex 64)"
    echo "SECRET_KEY=${SECRET}" >> "$ENV_FILE"
fi

# ===============================
# DATABASE_URL (avec détection)
# ===============================
DB_HOST="$(bashio::config 'DATABASE.db_host')"
DB_PORT="$(bashio::config 'DATABASE.db_port')"
DB_USER="$(bashio::config 'DATABASE.db_user')"
DB_PASSWORD="$(bashio::config 'DATABASE.db_password')"
DB_NAME="$(bashio::config 'DATABASE.db_name')"

NEW_DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

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
exec npm start --prod
