#!/usr/bin/env bashio
set -euo pipefail

ENV_FILE="/config/.env"
PLANKA_ENV="/opt/planka/.env"

bashio::log.info "Initialisation Planka"

# ===============================
# HELPERS
# ===============================
set_env() {
    local key="$1"
    local value="$2"
    local changed_ref="$3"

    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        local current
        current="$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-)"
        if [[ "$current" != "$value" ]]; then
            bashio::log.info "Mise à jour ${key}"
            sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
            eval "$changed_ref=true"
        fi
    else
        bashio::log.info "Ajout ${key}"
        echo "${key}=${value}" >> "$ENV_FILE"
        eval "$changed_ref=true"
    fi
}

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
set_env "DATABASE_URL" "$NEW_DATABASE_URL" DB_CHANGED

# ===============================
# BASE_URL (détection)
# ===============================
BASE_URL="http://localhost:1338"
ENV_CHANGED=false
set_env "BASE_URL" "$BASE_URL" ENV_CHANGED

# ===============================
# ADMIN (premier démarrage uniquement)
# ===============================
if ! grep -q "^DEFAULT_ADMIN_EMAIL=" "$ENV_FILE" 2>/dev/null; then
    bashio::log.info "Création admin initial"

    ADMIN_EMAIL="$(bashio::config 'ADMIN.email')"
    ADMIN_PASSWORD="$(bashio::config 'ADMIN.password')"
    ADMIN_NAME="$(bashio::config 'ADMIN.name')"

    echo "DEFAULT_ADMIN_EMAIL=${ADMIN_EMAIL}" >> "$ENV_FILE"
    echo "DEFAULT_ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> "$ENV_FILE"
    echo "DEFAULT_ADMIN_NAME=${ADMIN_NAME}" >> "$ENV_FILE"

    ENV_CHANGED=true
fi

# ===============================
# PERMISSIONS + SYNC
# ===============================
chmod 600 "$ENV_FILE"

if [[ ! -f "$PLANKA_ENV" ]] || ! cmp -s "$ENV_FILE" "$PLANKA_ENV"; then
    bashio::log.info "Synchronisation .env vers Planka"
    cp "$ENV_FILE" "$PLANKA_ENV"
    chmod 600 "$PLANKA_ENV"
fi

cd /opt/planka

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
