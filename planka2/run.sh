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
# GET EXTERNAL URL LIKE N8N
# ===============================
# Try to get Supervisor info, but handle errors gracefully
SUPERVISOR_TOKEN=${SUPERVISOR_TOKEN:-}
INFO='{}'
CONFIG='{}'
ADDON_INFO='{}'

if [[ -n "$SUPERVISOR_TOKEN" ]]; then
    INFO=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/info 2>/dev/null || echo '{}')
    CONFIG=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/core/api/config 2>/dev/null || echo '{}')
    ADDON_INFO=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/addons/self/info 2>/dev/null || echo '{}')
else
    bashio::log.warning "SUPERVISOR_TOKEN not set, using fallback hostname detection"
fi

# Ensure valid JSON
INFO=${INFO:-'{}'}
CONFIG=${CONFIG:-'{}'}
ADDON_INFO=${ADDON_INFO:-'{}'}

# Get the Home Assistant hostname from the supervisor info or fallback
LOCAL_HA_HOSTNAME=$(echo "$INFO" | jq -r '.data.hostname // "localhost"' 2>/dev/null || echo "localhost")
LOCAL_PLANKA_PORT=1337

# Get external URL if configured, otherwise use hostname and port
EXTERNAL_PLANKA_URL=$(echo "$CONFIG" | jq -r ".external_url // \"http://$LOCAL_HA_HOSTNAME:1339\"" 2>/dev/null || echo "http://$LOCAL_HA_HOSTNAME:1339")
EXTERNAL_HOSTNAME=$(echo "$EXTERNAL_PLANKA_URL" | sed -e "s/https\?:\/\///" | cut -d':' -f1)

echo "External Planka URL: ${EXTERNAL_PLANKA_URL}"
echo "External Hostname: ${EXTERNAL_HOSTNAME}"

# ===============================
# BASE_URL
# ===============================
BASE_URL="http://localhost:1337"

if grep -q "^BASE_URL=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^BASE_URL=.*|BASE_URL=${BASE_URL}|" "$ENV_FILE"
else
    echo "BASE_URL=${BASE_URL}" >> "$ENV_FILE"
fi

# ===============================
# ADDITIONAL PLANKA ENV VARS
# ===============================
echo "NODE_ENV=${NODE_ENV:-production}" >> "$ENV_FILE"
echo "PORT=${PORT:-1337}" >> "$ENV_FILE"
echo "EXPLICIT_HOST=0.0.0.0" >> "$ENV_FILE"
echo "TRUST_PROXY=1" >> "$ENV_FILE"
echo "CLIENT_BASE_URL=${EXTERNAL_PLANKA_URL}" >> "$ENV_FILE"
echo "SERVER_BASE_URL=http://localhost:1337" >> "$ENV_FILE"
echo "PUBLIC_URL=${EXTERNAL_PLANKA_URL}" >> "$ENV_FILE"
echo "REACT_APP_BASE_URL=${EXTERNAL_PLANKA_URL}" >> "$ENV_FILE"
echo "CORS_ORIGIN=*" >> "$ENV_FILE"
echo "NODE_OPTIONS=--max-old-space-size=4096" >> "$ENV_FILE"
echo "UV_THREADPOOL_SIZE=16" >> "$ENV_FILE"

# Force Planka to use correct URLs
echo "EXTERNAL_HOST=$(bashio::info 'hostname')" >> "$ENV_FILE"
echo "EXTERNAL_URL=http://$(bashio::info 'hostname'):1339" >> "$ENV_FILE"

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
cd /app
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
exec node app.js
