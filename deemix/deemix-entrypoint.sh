#!/usr/bin/env bashio
# Point d'entrée Deemix : lit la config Home Assistant, prépare les dossiers
# et démarre le serveur web (Express + WebSocket) sur le port interne 6596.
# nginx (port 6595) proxyfie l'accès direct et l'Ingress HA vers ce backend.
set -euo pipefail

MUSIC_DIR="$(bashio::config 'music_folder')"
CONFIG_DIR="$(bashio::config 'config_folder')"
SINGLE_USER="$(bashio::config 'single_user')"

bashio::log.info "Dossier musique : ${MUSIC_DIR}"
bashio::log.info "Dossier config  : ${CONFIG_DIR}"
bashio::log.info "Mode single-user : ${SINGLE_USER}"

# Création des dossiers locaux uniquement (les montages smb://, nfs:// et
# les chemins /share, /media sont fournis par le Supervisor).
for dir in "${MUSIC_DIR}" "${CONFIG_DIR}"; do
    case "${dir}" in
        /*) mkdir -p "${dir}" || bashio::log.warning "Impossible de créer ${dir}" ;;
        *) bashio::log.info "Montage réseau, création ignorée : ${dir}" ;;
    esac
done

export DEEMIX_DATA_DIR="${CONFIG_DIR}"
export DEEMIX_MUSIC_DIR="${MUSIC_DIR}"
export DEEMIX_SERVER_PORT="6596"
export DEEMIX_HOST="127.0.0.1"
export NODE_ENV="production"

# bashio renvoie "true"/"false" pour les booléens : format attendu par deemix.
if bashio::var.true "${SINGLE_USER}"; then
    export DEEMIX_SINGLE_USER="true"
else
    export DEEMIX_SINGLE_USER="false"
fi

# Variables d'environnement libres (env_vars_list, format "CLE: valeur")
if bashio::config.has_value 'env_vars_list'; then
    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        KEY=$(printf '%s' "${line}" | cut -d: -f1 | tr -d ' ')
        VAL=$(printf '%s' "${line}" | cut -d: -f2- | sed 's/^ //')
        if [ -n "${KEY}" ]; then
            export "${KEY}=${VAL}"
            bashio::log.info "env: ${KEY} défini"
        fi
    done < <(bashio::config 'env_vars_list | .[]' 2>/dev/null || jq -r '.env_vars_list[]?' /data/options.json)
fi

bashio::log.info "Démarrage Deemix (node $(node --version))"
exec node /app/packages/webui/dist/main.js
