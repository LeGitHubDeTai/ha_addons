#!/bin/sh
# HA add-on entrypoint: loads /data/options.json into MINDWTR_* env vars,
# prepares directories/timezone, then starts supervisord.
# Children (mindwtr-cloud, nginx) inherit this environment.
set -eu

OPTIONS_FILE="/data/options.json"

opt_string() {
  # $1 = jq field name -> prints raw string or empty
  if [ -f "$OPTIONS_FILE" ]; then
    jq -r --arg k "$1" '.[$k] // empty | if type == "string" then . else tostring end' "$OPTIONS_FILE" 2>/dev/null || true
  fi
}

opt_int() {
  if [ -f "$OPTIONS_FILE" ]; then
    jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS_FILE" 2>/dev/null || true
  fi
}

if [ -f "$OPTIONS_FILE" ]; then
  # --- timezone ---
  TZ_OPT="$(opt_string timezone)"
  if [ -n "$TZ_OPT" ]; then
    export TZ="$TZ_OPT"
    if [ -f "/usr/share/zoneinfo/$TZ_OPT" ]; then
      cp "/usr/share/zoneinfo/$TZ_OPT" /etc/localtime 2>/dev/null || true
      echo "$TZ_OPT" > /etc/timezone 2>/dev/null || true
    fi
    echo "[mindwtr-entrypoint] timezone=$TZ_OPT"
  fi

  # --- main options (only override when non-empty) ---
  VAL="$(opt_string mindwtr_cloud_auth_tokens)"
  if [ -n "$VAL" ]; then export MINDWTR_CLOUD_AUTH_TOKENS="$VAL"; fi

  VAL="$(opt_string mindwtr_cloud_cors_origin)"
  if [ -n "$VAL" ]; then export MINDWTR_CLOUD_CORS_ORIGIN="$VAL"; fi

  VAL="$(opt_int mindwtr_cloud_max_body_bytes)"
  if [ -n "$VAL" ]; then export MINDWTR_CLOUD_MAX_BODY_BYTES="$VAL"; fi

  VAL="$(opt_int mindwtr_cloud_max_attachment_bytes)"
  if [ -n "$VAL" ]; then export MINDWTR_CLOUD_MAX_ATTACHMENT_BYTES="$VAL"; fi

  VAL="$(opt_string mindwtr_default_cloud_url)"
  # empty value must explicitly clear a preset env so runtime-config.json is removed
  export MINDWTR_DEFAULT_CLOUD_URL="$VAL"

  VAL="$(opt_string mindwtr_cloud_data_dir)"
  if [ -n "$VAL" ]; then export MINDWTR_CLOUD_DATA_DIR="$VAL"; fi

  VAL="$(opt_string cmd_line_args)"
  export MINDWTR_CMD_LINE_ARGS="$VAL"

  # --- extra env vars: list of "KEY: value" ---
  # NOTE: avoid `... | while read` (subshell would drop exports); use redirect.
  if jq -e '.env_vars_list | type == "array"' "$OPTIONS_FILE" >/dev/null 2>&1; then
    _env_tmp="$(mktemp)"
    jq -r '.env_vars_list[]? // empty' "$OPTIONS_FILE" > "$_env_tmp" 2>/dev/null || true
    while IFS= read -r line || [ -n "$line" ]; do
      [ -z "$line" ] && continue
      # split on first ":"
      key="$(printf '%s' "$line" | cut -d: -f1 | tr -d ' ')"
      value="$(printf '%s' "$line" | cut -d: -f2- | sed 's/^ *//')"
      case "$key" in
        ''|*[!A-Z_0-9]*) echo "[mindwtr-entrypoint] ignoring invalid env key: $key" >&2; continue ;;
      esac
      export "$key"="$value"
      echo "[mindwtr-entrypoint] extra env: $key"
    done < "$_env_tmp"
    rm -f "$_env_tmp"
  fi
fi

# --- defaults ---
: "${MINDWTR_CLOUD_DATA_DIR:=/share/mindwtr}"
export MINDWTR_CLOUD_DATA_DIR
: "${MINDWTR_CLOUD_AUTH_TOKENS:=}"
: "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:=}"
: "${MINDWTR_CLOUD_CORS_ORIGIN:=}"
: "${MINDWTR_CLOUD_MAX_BODY_BYTES:=2000000}"
: "${MINDWTR_CLOUD_MAX_ATTACHMENT_BYTES:=50000000}"
: "${MINDWTR_DEFAULT_CLOUD_URL:=}"
: "${MINDWTR_CMD_LINE_ARGS:=}"
export MINDWTR_CLOUD_AUTH_TOKENS MINDWTR_CLOUD_AUTH_TOKENS_FILE \
  MINDWTR_CLOUD_CORS_ORIGIN MINDWTR_CLOUD_MAX_BODY_BYTES \
  MINDWTR_CLOUD_MAX_ATTACHMENT_BYTES MINDWTR_DEFAULT_CLOUD_URL

# Backward-compat: old installs defaulted to the ephemeral /app/cloud_data.
# Keep supporting it, but prefer the persisted /share/mindwtr.
mkdir -p "$MINDWTR_CLOUD_DATA_DIR" /app/cloud_data /share/mindwtr 2>/dev/null || true
mkdir -p /run/mindwtr-cloud 2>/dev/null || true
chown bun:bun "$MINDWTR_CLOUD_DATA_DIR" /run/mindwtr-cloud 2>/dev/null \
  || chown 1000:1000 "$MINDWTR_CLOUD_DATA_DIR" /run/mindwtr-cloud 2>/dev/null || true

if [ -z "$MINDWTR_CLOUD_AUTH_TOKENS" ] && [ -z "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" ]; then
  echo "[mindwtr-entrypoint] WARNING: no sync token configured." >&2
  echo "[mindwtr-entrypoint] Set 'mindwtr_cloud_auth_tokens' (20+ chars) in the add-on options, then restart." >&2
  echo "[mindwtr-entrypoint] The web UI on :8080 will still start; cloud sync on :8787 will refuse to start until a token is set." >&2
fi

echo "[mindwtr-entrypoint] data_dir=$MINDWTR_CLOUD_DATA_DIR cors_origin=${MINDWTR_CLOUD_CORS_ORIGIN:-<empty>}"

exec /usr/bin/supervisord -c /etc/supervisord.conf
