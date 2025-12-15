#!/usr/bin/env bashio
set -euo pipefail

ENV_FILE="/data/.env"

bashio::log.info "Initialisation Planka"

# ===============================
# HELPERS
# ===============================
set_env() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        CURRENT_VALUE="$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-)"
        if [[ "$CURRENT_VALUE" != "$value" ]]; then
            bashio::log.info "Mise à jour ${key}"
            sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
        fi
    else
        bashio::log.info "Ajout ${key}"
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}

# ===============================
# SECRET (jamais modifié)
# ===============================
if [[ ! -f "$ENV_FILE" ]] || ! grep -q "^SECRET=" "$ENV_FILE"; then
    bashio::log.info "Génération du SECRET"
    SECRET="$(openssl rand -hex 64)"
    echo "SECRET=${SECRET}" >> "$ENV_FILE"
fi

# ===============================
# DATABASE_URL
# ===============================
DB_HOST="$(bashio::config 'DATABASE.db_host')"
DB_PORT="$(bashio::config 'DATABASE.db_port')"
DB_USER="$(bashio::config 'DATABASE.db_user')"
DB_PASSWORD="$(bashio::config 'DATABASE.db_password')"
DB_NAME="$(bashio::config 'DATABASE.db_name')"

DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
set_env "DATABASE_URL" "$DATABASE_URL"
exec npm run db:init

# ===============================
# BASE_URL
# ===============================
BASE_URL="http://localhost:1337"
set_env "BASE_URL" "$BASE_URL"

# ===============================
# ADMIN (1er démarrage uniquement)
# ===============================
if ! grep -q "^DEFAULT_ADMIN_EMAIL=" "$ENV_FILE" 2>/dev/null; then
    ADMIN_EMAIL="$(bashio::config 'ADMIN.email')"
    ADMIN_PASSWORD="$(bashio::config 'ADMIN.password')"
    ADMIN_NAME="$(bashio::config 'ADMIN.name')"

    bashio::log.info "Création admin initial"
    echo "DEFAULT_ADMIN_EMAIL=${ADMIN_EMAIL}" >> "$ENV_FILE"
    echo "DEFAULT_ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> "$ENV_FILE"
    echo "DEFAULT_ADMIN_NAME=${ADMIN_NAME}" >> "$ENV_FILE"
else
    bashio::log.info "Admin déjà créé (non modifié)"
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
