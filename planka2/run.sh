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
# ADDITIONAL PLANKA ENV VARS (officiel)
# ===============================
echo "PORT=${PORT:-1337}" >> "$ENV_FILE"
echo "EXPLICIT_HOST=0.0.0.0" >> "$ENV_FILE"
echo "TRUST_PROXY=true" >> "$ENV_FILE"
echo "SERVER_BASE_URL=http://localhost:1337" >> "$ENV_FILE"
echo "CORS_ORIGIN=*" >> "$ENV_FILE"
echo "NODE_OPTIONS=--max-old-space-size=4096" >> "$ENV_FILE"
echo "UV_THREADPOOL_SIZE=16" >> "$ENV_FILE"
echo "SOCKETS_ONLY_ALLOW_ORIGINS=*" >> "$ENV_FILE"
echo "SOCKETS_CORS_ALLOW_ORIGINS=*" >> "$ENV_FILE"
echo "ALLOWED_ORIGINS=*" >> "$ENV_FILE"
echo "SOCKET_ORIGINS=*" >> "$ENV_FILE"
echo "HOOK_TIMEOUT=80000" >> "$ENV_FILE"
echo "NODE_ENV=production" >> "$ENV_FILE"
echo "SESSION_COOKIE_SECURE=false" >> "$ENV_FILE"
echo "SESSION_STORE=memory" >> "$ENV_FILE"
echo "SOCKETS_ONLY_ALLOW_ORIGINS=*" >> "$ENV_FILE"
echo "SOCKETS_CORS_ALLOW_ORIGINS=*" >> "$ENV_FILE"
echo "CORS_ORIGIN=*" >> "$ENV_FILE"
echo "TRUST_PROXY=true" >> "$ENV_FILE"
echo "sails.config.http.trustProxy=true" >> "$ENV_FILE"
echo "sails.config.sockets.onlyAllowOrigins=*" >> "$ENV_FILE"
echo "sails.config.session.cookie.secure=false" >> "$ENV_FILE"
echo "sails.config.session.secret=$SECRET_KEY" >> "$ENV_FILE"
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
# CREATE REQUIRED DIRECTORIES
# ===============================
mkdir -p /opt/planka/.tmp/public/preloaded-favicons
mkdir -p /opt/planka/.tmp/public/preloaded-logos
mkdir -p /opt/planka/.tmp/public/preloaded-background-images
mkdir -p /opt/planka/data/uploads
mkdir -p /opt/planka/data/avatars

# ===============================
# INITIALIZE ENVIRONMENT
# ===============================
cd /opt/planka
cp $ENV_FILE ./
chmod 600 "$ENV_FILE"
chmod 600 "./.env"
chmod +x "./start.sh"

# ===============================
# DATABASE RESET IF NEEDED
# ===============================
# Check if database needs reset due to missing migrations
if [ "$DB_CHANGED" = true ] || [ ! -f "/opt/planka/server/db/migrations/20260312000000_add_ability_to_display_card_ages.js" ]; then
    bashio::log.warning "Réinitialisation de la base de données (migration manquante)"
    
    # Create missing migration file
    mkdir -p /opt/planka/server/db/migrations
    cat > /opt/planka/server/db/migrations/20260312000000_add_ability_to_display_card_ages.js << 'EOF'
'use strict';

exports.up = function(knex) {
    return knex.schema.table('cards', function(table) {
        table.boolean('displayCardAges').defaultTo(false);
    });
};

exports.down = function(knex) {
    return knex.schema.table('cards', function(table) {
        table.dropColumn('displayCardAges');
    });
};
EOF
    
    # Drop and recreate database
    export PGPASSWORD="$DB_PASSWORD"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || true
    unset PGPASSWORD
fi

# ===============================
# EXPORT VARIABLES FOR START.SH
# ===============================
# Export all variables to environment for start.sh
while IFS= read -r line; do
    if [[ "$line" =~ ^[A-Z_]+= ]]; then
        export "$line"
    fi
done < "$ENV_FILE"

# Ensure WebSocket variables are directly exported
export SOCKETS_ONLY_ALLOW_ORIGINS="*"
export SOCKETS_CORS_ALLOW_ORIGINS="*"
export CORS_ORIGIN="*"
export ALLOWED_ORIGINS="*"
export SOCKET_ORIGINS="*"
export HOOK_TIMEOUT=80000
export NODE_ENV=production
export EXPLICIT_HOST=0.0.0.0
export TRUST_PROXY=true
export sails_config__http__trustProxy="true"
export sails_config__sockets__onlyAllowOrigins="*"
export sails_config__session__cookie__secure="false"
export sails_config__session__secret="$SECRET_KEY"
export SESSION_COOKIE_SECURE="false"
export SESSION_STORE="memory"

# ===============================
# START PLANKA
# ===============================
bashio::log.info "Démarrage Planka avec start.sh officiel"
exec ./start.sh
