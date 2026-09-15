#!/usr/bin/env bashio
set -euo pipefail

ENV_FILE="/config/.env"

bashio::log.info "Initialisation Fizzy"

# ===============================
# SECRET_KEY_BASE (jamais modifié)
# ===============================
if [[ ! -f "$ENV_FILE" ]] || ! grep -q "^SECRET_KEY_BASE=" "$ENV_FILE"; then
    bashio::log.info "Génération du SECRET_KEY_BASE"
    SECRET="$(openssl rand -hex 64)"
    echo "SECRET_KEY_BASE=${SECRET}" >> "$ENV_FILE"
fi

# ===============================
# CONFIGURATION
# ===============================

# TLS_DOMAIN
TLS_DOMAIN="$(bashio::config 'TLS_DOMAIN')"
if [[ -n "$TLS_DOMAIN" ]]; then
    if grep -q "^TLS_DOMAIN=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^TLS_DOMAIN=.*|TLS_DOMAIN=${TLS_DOMAIN}|" "$ENV_FILE"
    else
        echo "TLS_DOMAIN=${TLS_DOMAIN}" >> "$ENV_FILE"
    fi
    bashio::log.info "TLS_DOMAIN configuré: ${TLS_DOMAIN}"
else
    bashio::log.info "TLS_DOMAIN non configuré, désactivation du SSL"
    if grep -q "^DISABLE_SSL=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^DISABLE_SSL=.*|DISABLE_SSL=true|" "$ENV_FILE"
    else
        echo "DISABLE_SSL=true" >> "$ENV_FILE"
    fi
fi

# BASE_URL
BASE_URL="$(bashio::config 'BASE_URL')"
if [[ -n "$BASE_URL" ]]; then
    if grep -q "^BASE_URL=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^BASE_URL=.*|BASE_URL=${BASE_URL}|" "$ENV_FILE"
    else
        echo "BASE_URL=${BASE_URL}" >> "$ENV_FILE"
    fi
fi

# MAILER_FROM_ADDRESS
MAILER_FROM_ADDRESS="$(bashio::config 'MAILER_FROM_ADDRESS')"
if [[ -n "$MAILER_FROM_ADDRESS" ]]; then
    if grep -q "^MAILER_FROM_ADDRESS=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^MAILER_FROM_ADDRESS=.*|MAILER_FROM_ADDRESS=${MAILER_FROM_ADDRESS}|" "$ENV_FILE"
    else
        echo "MAILER_FROM_ADDRESS=${MAILER_FROM_ADDRESS}" >> "$ENV_FILE"
    fi
fi

# SMTP Configuration
SMTP_ADDRESS="$(bashio::config 'SMTP_ADDRESS')"
SMTP_PORT="$(bashio::config 'SMTP_PORT')"
SMTP_USERNAME="$(bashio::config 'SMTP_USERNAME')"
SMTP_PASSWORD="$(bashio::config 'SMTP_PASSWORD')"
SMTP_TLS="$(bashio::config 'SMTP_TLS')"

if [[ -n "$SMTP_ADDRESS" ]]; then
    # SMTP_ADDRESS
    if grep -q "^SMTP_ADDRESS=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^SMTP_ADDRESS=.*|SMTP_ADDRESS=${SMTP_ADDRESS}|" "$ENV_FILE"
    else
        echo "SMTP_ADDRESS=${SMTP_ADDRESS}" >> "$ENV_FILE"
    fi

    # SMTP_PORT
    if grep -q "^SMTP_PORT=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^SMTP_PORT=.*|SMTP_PORT=${SMTP_PORT}|" "$ENV_FILE"
    else
        echo "SMTP_PORT=${SMTP_PORT}" >> "$ENV_FILE"
    fi

    # SMTP_USERNAME
    if [[ -n "$SMTP_USERNAME" ]]; then
        if grep -q "^SMTP_USERNAME=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^SMTP_USERNAME=.*|SMTP_USERNAME=${SMTP_USERNAME}|" "$ENV_FILE"
        else
            echo "SMTP_USERNAME=${SMTP_USERNAME}" >> "$ENV_FILE"
        fi
    fi

    # SMTP_PASSWORD
    if [[ -n "$SMTP_PASSWORD" ]]; then
        if grep -q "^SMTP_PASSWORD=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^SMTP_PASSWORD=.*|SMTP_PASSWORD=${SMTP_PASSWORD}|" "$ENV_FILE"
        else
            echo "SMTP_PASSWORD=${SMTP_PASSWORD}" >> "$ENV_FILE"
        fi
    fi

    # SMTP_TLS
    if grep -q "^SMTP_TLS=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^SMTP_TLS=.*|SMTP_TLS=${SMTP_TLS}|" "$ENV_FILE"
    else
        echo "SMTP_TLS=${SMTP_TLS}" >> "$ENV_FILE"
    fi

    bashio::log.info "SMTP configuré: ${SMTP_ADDRESS}:${SMTP_PORT}"
fi

# VAPID Keys
VAPID_PRIVATE_KEY="$(bashio::config 'VAPID_PRIVATE_KEY')"
VAPID_PUBLIC_KEY="$(bashio::config 'VAPID_PUBLIC_KEY')"

if [[ -n "$VAPID_PRIVATE_KEY" ]]; then
    if grep -q "^VAPID_PRIVATE_KEY=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^VAPID_PRIVATE_KEY=.*|VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}|" "$ENV_FILE"
    else
        echo "VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}" >> "$ENV_FILE"
    fi
fi

if [[ -n "$VAPID_PUBLIC_KEY" ]]; then
    if grep -q "^VAPID_PUBLIC_KEY=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^VAPID_PUBLIC_KEY=.*|VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}|" "$ENV_FILE"
    else
        echo "VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}" >> "$ENV_FILE"
    fi
fi

# ===============================
# STORAGE DIRECTORY
# ===============================
STORAGE_DIR="/rails/storage"
mkdir -p "$STORAGE_DIR"
chown -R 1000:1000 "$STORAGE_DIR"

# ===============================
# COPY ENV FILE TO APPLICATION
# ===============================
cp "$ENV_FILE" /opt/fizzy/.env 2>/dev/null || true

# ===============================
# DOWNLOAD AND SETUP FIZZY
# ===============================
bashio::log.info "Téléchargement de Fizzy..."

# Download the latest Fizzy release
FIZZY_VERSION="3068c2a74da2e6d1cba38e7cf15b0dc158dbf2fe"
FIZZY_URL="https://github.com/basecamp/fizzy/archive/refs/heads/${FIZZY_VERSION}.zip"

# Create a temporary directory for download
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download the release
curl -fsSL -o fizzy.zip "$FIZZY_URL" || {
    bashio::log.error "Échec du téléchargement de Fizzy"
    exit 1
}

# Extract the release
unzip -q fizzy.zip || {
    bashio::log.error "Échec de l'extraction de Fizzy"
    exit 1
}

# Move to the installation directory
rm -rf /opt/fizzy
mv "fizzy-${FIZZY_VERSION}" /opt/fizzy
rm -f fizzy.zip

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# ===============================
# INSTALL DEPENDENCIES
# ===============================
bashio::log.info "Installation des dépendances..."

cd /opt/fizzy

# Install Ruby dependencies
bundle install --deployment --without development test || {
    bashio::log.error "Échec de l'installation des gems"
    exit 1
}

# ===============================
# SETUP DATABASE
# ===============================
bashio::log.info "Configuration de la base de données..."

# Fizzy uses SQLite by default, stored in the storage volume
# Copy the env file to the application directory
cp "$ENV_FILE" .env

# Initialize the database
bin/rails db:prepare || {
    bashio::log.warning "Initialisation de la base de données"
    bin/rails db:create db:migrate || true
}

# ===============================
# PRECOMPILE ASSETS
# ===============================
bashio::log.info "Précompilation des assets..."

SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile || {
    bashio::log.warning "Échec de la précompilation des assets"
}

# ===============================
# START FIZZY
# ===============================
bashio::log.info "Démarrage de Fizzy..."

# Start the application with Thruster (the default production server)
exec bin/thrust bin/rails server -b 0.0.0.0 -p 80