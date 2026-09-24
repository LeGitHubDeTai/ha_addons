#!/usr/bin/env bashio
# shellcheck disable=SC1091
set -euo pipefail

DATA_DIR="/data"
ENV_FILE="${DATA_DIR}/fizzy.env"
mkdir -p "${DATA_DIR}"
touch "${ENV_FILE}"

bashio::log.info "Initialisation Fizzy"

# Charge les valeurs persistées (si elles existent) pour ne pas régénérer à chaque reboot
set -a
# shellcheck disable=SC1090
[ -s "${ENV_FILE}" ] && source "${ENV_FILE}"
set +a

# Lecture option HA avec fallback sur l'env du conteneur (envs fournis par Home Assistant / supervisor)
# Priorité : /data/options.json (sans API, sans spam) -> bashio::config -> env conteneur -> défaut
# Usage: opt <CLE_BASHIO> <NOM_ENV> [defaut]
opt() {
    local key="${1}"
    local env_name="${2}"
    local default="${3:-}"
    local val=""

    if [[ -f /data/options.json ]] && command -v jq >/dev/null 2>&1; then
        val="$(jq -r --arg k "${key}" '.[$k] // empty' /data/options.json 2>/dev/null || true)"
    fi
    if [[ -z "${val}" || "${val}" == "null" ]] && bashio::config.exists "${key}" >/dev/null 2>&1; then
        val="$(bashio::config "${key}" 2>/dev/null || true)"
    fi
    if [[ -z "${val}" || "${val}" == "null" ]]; then
        # fallback : env déjà présent dans le conteneur (Home Assistant, docker -e, .env sourcé)
        val="${!env_name:-}"
    fi
    if [[ -z "${val}" ]]; then
        val="${default}"
    fi
    printf '%s' "${val}"
}

generate_secret() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 64
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import secrets; print(secrets.token_hex(64))'
    else
        # fallback busybox : 64 octets random en hex
        head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n'
    fi
}

# ===============================
# SECRET_KEY_BASE (persisté, jamais régénéré si déjà connu)
# ===============================
SECRET_KEY_BASE="$(opt 'SECRET_KEY_BASE' 'SECRET_KEY_BASE' '')"
if [[ -z "${SECRET_KEY_BASE}" ]]; then
    bashio::log.info "Génération du SECRET_KEY_BASE"
    SECRET_KEY_BASE="$(generate_secret)"
fi

# ===============================
# AUTRES OPTIONS -> ENVS
# ===============================
TLS_DOMAIN="$(opt 'TLS_DOMAIN' 'TLS_DOMAIN' '')"
BASE_URL="$(opt 'BASE_URL' 'BASE_URL' '')"
MAILER_FROM_ADDRESS="$(opt 'MAILER_FROM_ADDRESS' 'MAILER_FROM_ADDRESS' '')"
SMTP_ADDRESS="$(opt 'SMTP_ADDRESS' 'SMTP_ADDRESS' '')"
SMTP_PORT="$(opt 'SMTP_PORT' 'SMTP_PORT' '587')"
SMTP_USERNAME="$(opt 'SMTP_USERNAME' 'SMTP_USERNAME' '')"
SMTP_PASSWORD="$(opt 'SMTP_PASSWORD' 'SMTP_PASSWORD' '')"
SMTP_TLS="$(opt 'SMTP_TLS' 'SMTP_TLS' '')"
VAPID_PRIVATE_KEY="$(opt 'VAPID_PRIVATE_KEY' 'VAPID_PRIVATE_KEY' '')"
VAPID_PUBLIC_KEY="$(opt 'VAPID_PUBLIC_KEY' 'VAPID_PUBLIC_KEY' '')"

# Normalise le booléen HA (true/false) pour Rails
if [[ "${SMTP_TLS}" == "true" || "${SMTP_TLS}" == "True" || "${SMTP_TLS}" == "1" ]]; then
    SMTP_TLS="true"
else
    SMTP_TLS=""
fi

# SSL : si pas de TLS_DOMAIN, on désactive explicitement le SSL (usage local / ingress HA)
if [[ -z "${TLS_DOMAIN}" ]]; then
    DISABLE_SSL="true"
    bashio::log.info "TLS_DOMAIN vide -> DISABLE_SSL=true"
else
    DISABLE_SSL=""
    bashio::log.info "TLS_DOMAIN configuré: ${TLS_DOMAIN}"
fi

# ===============================
# EXPORT VERS L'APP (c'est ce que Rails/Thruster lisent)
# ===============================
export SECRET_KEY_BASE
export TLS_DOMAIN
export DISABLE_SSL
export BASE_URL
export MAILER_FROM_ADDRESS
export SMTP_ADDRESS
export SMTP_PORT
export SMTP_USERNAME
export SMTP_PASSWORD
export SMTP_TLS
export VAPID_PRIVATE_KEY
export VAPID_PUBLIC_KEY
export RAILS_ENV="production"
export PORT="80"

# ===============================
# PERSISTE (sans logger les secrets)
# ===============================
{
    echo "SECRET_KEY_BASE=${SECRET_KEY_BASE}"
    echo "TLS_DOMAIN=${TLS_DOMAIN}"
    echo "DISABLE_SSL=${DISABLE_SSL}"
    echo "BASE_URL=${BASE_URL}"
    echo "MAILER_FROM_ADDRESS=${MAILER_FROM_ADDRESS}"
    echo "SMTP_ADDRESS=${SMTP_ADDRESS}"
    echo "SMTP_PORT=${SMTP_PORT}"
    echo "SMTP_USERNAME=${SMTP_USERNAME}"
    echo "SMTP_PASSWORD=${SMTP_PASSWORD}"
    echo "SMTP_TLS=${SMTP_TLS}"
    echo "VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}"
    echo "VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}"
} > "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

bashio::log.info "Variables d'environnement exportées (SECRET masqué)"

# ===============================
# STORAGE DIRECTORY
# ===============================
STORAGE_DIR="/rails/storage"
mkdir -p "$STORAGE_DIR"
chown -R 1000:1000 "$STORAGE_DIR" 2>/dev/null || true

# ===============================
# COPY ENV FILE TO APPLICATION
# ===============================
cp "$ENV_FILE" /opt/fizzy/.env 2>/dev/null || true

# ===============================
# DOWNLOAD AND SETUP FIZZY
# ===============================
bashio::log.info "Téléchargement de Fizzy..."

# Download the latest Fizzy release
FIZZY_VERSION="main"
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

# Bundler 4 a supprimé les flags --deployment / --without -> passer par `bundle config`
export BUNDLE_SILENCE_ROOT_WARNING=1
bundle config set deployment true
bundle config set without 'development test'
bundle install || {
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
