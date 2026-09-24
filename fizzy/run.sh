#!/bin/bash
# Fizzy tourne depuis l'image officielle pré-construite.
# Ce script ne fait que : config (options HA -> envs), stockage persistant, db:prepare, démarrage.
set -euo pipefail

# Digest de l'image upstream suivie (mis à jour par le workflow auto-upgrade-fizzy).
FIZZY_DIGEST="sha256:6a7ea6a988179ce1cb4158324a9dad0408ea5c4ca5a1a1912adcb90e5abacce8"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

OPTIONS_FILE="/data/options.json"
SECRET_FILE="/data/fizzy.env"

mkdir -p /data
touch "$SECRET_FILE"
chmod 600 "$SECRET_FILE" 2>/dev/null || true

# Secret persisté (généré une seule fois, jamais régénéré ensuite)
set -a
if [ -s "$SECRET_FILE" ]; then
    # shellcheck disable=SC1090
    source "$SECRET_FILE"
fi
set +a

# Option HA (/data/options.json) -> env du conteneur -> défaut
opt() {
    local key="$1" env_name="$2" default="${3:-}" val=""
    if [[ -f "$OPTIONS_FILE" ]] && command -v jq >/dev/null 2>&1; then
        val="$(jq -r --arg k "$key" '.[$k] // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
    fi
    if [[ -z "$val" || "$val" == "null" ]]; then
        val="${!env_name:-}"
    fi
    if [[ -z "$val" ]]; then
        val="$default"
    fi
    printf '%s' "$val"
}

generate_secret() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 64
    else
        head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n'
    fi
}

export_or_unset() {
    local name="$1" val="$2"
    if [[ -n "$val" ]]; then
        export "$name=$val"
    else
        unset "$name" || true
    fi
}

log "Initialisation Fizzy"

SECRET_KEY_BASE="$(opt 'SECRET_KEY_BASE' 'SECRET_KEY_BASE' '')"
if [[ -z "$SECRET_KEY_BASE" ]]; then
    log "Génération du SECRET_KEY_BASE"
    SECRET_KEY_BASE="$(generate_secret)"
fi
printf 'SECRET_KEY_BASE=%s\n' "$SECRET_KEY_BASE" > "$SECRET_FILE"
chmod 600 "$SECRET_FILE"
export SECRET_KEY_BASE
export RAILS_ENV="production"

TLS_DOMAIN="$(opt 'TLS_DOMAIN' 'TLS_DOMAIN' '')"
BASE_URL="$(opt 'BASE_URL' 'BASE_URL' '')"
MAILER_FROM_ADDRESS="$(opt 'MAILER_FROM_ADDRESS' 'MAILER_FROM_ADDRESS' '')"
SMTP_ADDRESS="$(opt 'SMTP_ADDRESS' 'SMTP_ADDRESS' '')"
SMTP_PORT="$(opt 'SMTP_PORT' 'SMTP_PORT' '')"
SMTP_USERNAME="$(opt 'SMTP_USERNAME' 'SMTP_USERNAME' '')"
SMTP_PASSWORD="$(opt 'SMTP_PASSWORD' 'SMTP_PASSWORD' '')"
SMTP_TLS="$(opt 'SMTP_TLS' 'SMTP_TLS' '')"
VAPID_PRIVATE_KEY="$(opt 'VAPID_PRIVATE_KEY' 'VAPID_PRIVATE_KEY' '')"
VAPID_PUBLIC_KEY="$(opt 'VAPID_PUBLIC_KEY' 'VAPID_PUBLIC_KEY' '')"

if [[ "$SMTP_TLS" == "true" || "$SMTP_TLS" == "True" || "$SMTP_TLS" == "1" ]]; then
    SMTP_TLS="true"
else
    SMTP_TLS=""
fi

if [[ -z "$TLS_DOMAIN" ]]; then
    DISABLE_SSL="true"
    log "TLS_DOMAIN vide -> DISABLE_SSL=true"
else
    DISABLE_SSL=""
    log "TLS_DOMAIN configuré: $TLS_DOMAIN"
fi

# SMTP local (Mailpit) par défaut -> zéro config.
# Dès qu'un vrai serveur SMTP est renseigné, il prend le dessus.
SMTP_LOCAL=false
if [[ -z "$SMTP_ADDRESS" ]]; then
    SMTP_ADDRESS="127.0.0.1"
    if [[ -z "$SMTP_PORT" ]]; then
        SMTP_PORT="1025"
    fi
    SMTP_USERNAME=""
    SMTP_PASSWORD=""
    SMTP_TLS=""
    SMTP_LOCAL=true
else
    if [[ -z "$SMTP_PORT" ]]; then
        SMTP_PORT="587"
    fi
fi
if [[ -z "$MAILER_FROM_ADDRESS" ]]; then
    MAILER_FROM_ADDRESS="fizzy@localhost"
fi

export_or_unset 'TLS_DOMAIN' "$TLS_DOMAIN"
export_or_unset 'DISABLE_SSL' "$DISABLE_SSL"
export_or_unset 'BASE_URL' "$BASE_URL"
export_or_unset 'MAILER_FROM_ADDRESS' "$MAILER_FROM_ADDRESS"
export_or_unset 'SMTP_ADDRESS' "$SMTP_ADDRESS"
export_or_unset 'SMTP_PORT' "$SMTP_PORT"
export_or_unset 'SMTP_USERNAME' "$SMTP_USERNAME"
export_or_unset 'SMTP_PASSWORD' "$SMTP_PASSWORD"
export_or_unset 'SMTP_TLS' "$SMTP_TLS"
export_or_unset 'VAPID_PRIVATE_KEY' "$VAPID_PRIVATE_KEY"
export_or_unset 'VAPID_PUBLIC_KEY' "$VAPID_PUBLIC_KEY"

log "Variables d'environnement exportées (secrets masqués)"

if [[ "$SMTP_LOCAL" == "true" ]]; then
    mkdir -p /data/mailpit
    log "Démarrage du SMTP local (Mailpit)..."
    /usr/local/bin/mailpit \
        --smtp 127.0.0.1:1025 \
        --listen 0.0.0.0:8025 \
        --data-file /data/mailpit/mailpit.db \
        >> /data/mailpit/mailpit.log 2>&1 &
    log "Boîte mail locale dispo sur le port 8097 (codes de connexion)"
else
    log "SMTP configuré: ${SMTP_ADDRESS}:${SMTP_PORT}"
fi

# Stockage persistant : /rails/storage -> /data/storage (SQLite + uploads)
mkdir -p /data/storage
if [[ ! -L /rails/storage ]]; then
    if [[ -d /rails/storage ]]; then
        cp -a /rails/storage/. /data/storage/ 2>/dev/null || true
        rm -rf /rails/storage
    fi
    ln -s /data/storage /rails/storage
    log "Stockage persistant: /rails/storage -> /data/storage"
fi

cd /rails

log "Préparation de la base de données..."
bin/rails db:prepare

log "Démarrage de Fizzy..."
exec ./bin/thrust ./bin/rails server
