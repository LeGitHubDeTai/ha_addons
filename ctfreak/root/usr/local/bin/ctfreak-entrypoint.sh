#!/usr/bin/env bash
# Entrypoint CTFREAK : applique les options de l'add-on Home Assistant
# (TZ, data_dir) puis lance le binaire upstream `ctfreak -c <data_dir> run`.
set -e

if ! command -v bashio::config >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  for _bashio in /usr/lib/bashio/bashio.sh /usr/local/lib/bashio-standalone.sh; do
    if [ -f "$_bashio" ]; then
      . "$_bashio"
      break
    fi
  done
fi

HA_TZ="$(bashio::config 'TZ')"
DATA_DIR="$(bashio::config 'data_dir')"

export TZ="$HA_TZ"

bashio::log.info "Options HA : TZ=${HA_TZ} data_dir=${DATA_DIR}"

if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR" || bashio::log.warning "Impossible de créer ${DATA_DIR}"
fi

exec /usr/bin/ctfreak -c "$DATA_DIR" run
