#!/bin/bash
set -euo pipefail

for _bashio in /usr/lib/bashio/bashio.sh /usr/local/lib/bashio-standalone.sh; do
    if [ -f "${_bashio}" ]; then
        source "${_bashio}"
        break
    fi
done

TZ="$(bashio::config 'timezone')"
[ -z "${TZ}" ] || [ "${TZ}" = "null" ] && TZ="Europe/Berlin"
export TZ

DOWNLOAD_DIR="$(bashio::config 'download_folder')"
CONFIG_DIR="$(bashio::config 'config_folder')"
MAX_PARALLEL="$(bashio::config 'max_parallel')"

[ -z "${DOWNLOAD_DIR}" ] || [ "${DOWNLOAD_DIR}" = "null" ] && DOWNLOAD_DIR="/media/youtube-dl"
[ -z "${CONFIG_DIR}" ] || [ "${CONFIG_DIR}" = "null" ] && CONFIG_DIR="/share/youtube-dl"
[ -z "${MAX_PARALLEL}" ] || [ "${MAX_PARALLEL}" = "null" ] && MAX_PARALLEL=3

for dir in "${DOWNLOAD_DIR}" "${CONFIG_DIR}"; do
    case "${dir}" in
        /*) mkdir -p "${dir}" 2>/dev/null || bashio::log.warning "Impossible de créer ${dir}" ;;
        *) bashio::log.info "Montage réseau, création ignorée : ${dir}" ;;
    esac
done

export YTDLP_DOWNLOAD_DIR="${DOWNLOAD_DIR}"
export YTDLP_CONFIG_DIR="${CONFIG_DIR}"
export YTDLP_MAX_PARALLEL="${MAX_PARALLEL}"
export FLASK_APP=app.py
export FLASK_RUN_HOST=0.0.0.0
export FLASK_RUN_PORT=5001

bashio::log.info "Dossier téléchargements : ${DOWNLOAD_DIR}"
bashio::log.info "Dossier config : ${CONFIG_DIR}"
bashio::log.info "Téléchargements parallèles max : ${MAX_PARALLEL}"

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

bashio::log.info "Démarrage de l'interface web YouTube-DL (Flask + yt-dlp)"
exec python3 /app/webapp/app.py