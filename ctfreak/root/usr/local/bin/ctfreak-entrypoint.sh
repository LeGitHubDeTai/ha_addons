#!/usr/bin/env bash
# Entrypoint CTFREAK : applique les options de l'add-on Home Assistant
# (TZ, data_dir, external_url, config_json) puis lance le binaire
# upstream `ctfreak -c <data_dir> run`.
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
EXTERNAL_URL="$(bashio::config 'external_url')"
CONFIG_JSON="$(bashio::config 'config_json')"

export TZ="$HA_TZ"

bashio::log.info "Options HA : TZ=${HA_TZ} data_dir=${DATA_DIR} external_url=${EXTERNAL_URL}"

if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR" || bashio::log.warning "Impossible de créer ${DATA_DIR}"
fi

# Inject global settings (Settings -> Global) into CTFREAK config.json
if [ -n "$CONFIG_JSON" ]; then
  if [ -f "$DATA_DIR/config.json" ]; then
    jq -s '.[0] * .[1]' "$DATA_DIR/config.json" <(echo "$CONFIG_JSON") > "$DATA_DIR/config.json.tmp" \
      && mv "$DATA_DIR/config.json.tmp" "$DATA_DIR/config.json" \
      || bashio::log.warning "Impossible de fusionner config.json"
  else
    echo "$CONFIG_JSON" > "$DATA_DIR/config.json" || bashio::log.warning "Impossible d'écrire config.json"
  fi
  bashio::log.info "config.json mis à jour"
fi

RUN_ARGS=""
if [ -n "$EXTERNAL_URL" ]; then
  RUN_ARGS="$RUN_ARGS -set-external-url=${EXTERNAL_URL}"
fi

exec /usr/bin/ctfreak -c "$DATA_DIR" run $RUN_ARGS
