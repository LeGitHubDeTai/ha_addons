#!/bin/sh
# HA add-on entrypoint: sync-only configuration.
# Reads /data/options.json (sync_mode, cloud_tokens, cors_origin),
# exports the MINDWTR_* environment, then starts supervisord.
# Children (mindwtr-cloud, nginx) inherit this environment.
# Everything else is automatic: data dir, ports, runtime-config.
set -eu

OPTIONS_FILE="/data/options.json"
DATA_DIR="/share/mindwtr"

opt_string() {
  # $1 = jq field name -> prints raw string or empty
  if [ -f "$OPTIONS_FILE" ]; then
    jq -r --arg k "$1" '.[$k] // empty | if type == "string" then . else tostring end' "$OPTIONS_FILE" 2>/dev/null || true
  fi
}

# --- sync mode (default: local folders only) ---
SYNC_MODE="$(opt_string sync_mode)"
SYNC_MODE="$(printf '%s' "$SYNC_MODE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
if [ -z "$SYNC_MODE" ]; then
  # Migration: installs configured before sync_mode existed used
  # mindwtr_cloud_auth_tokens directly -> treat as selfhosted.
  if [ -n "$(opt_string mindwtr_cloud_auth_tokens)" ]; then
    SYNC_MODE="selfhosted"
  else
    SYNC_MODE="local"
  fi
fi
case "$SYNC_MODE" in
  local|selfhosted|webdav|dropbox) ;;
  *)
    echo "[mindwtr-entrypoint] WARNING: unknown sync_mode '$SYNC_MODE', falling back to 'local'." >&2
    SYNC_MODE="local"
    ;;
esac
export SYNC_MODE

# --- tokens: new key first, legacy key as fallback ---
TOKENS="$(opt_string cloud_tokens)"
if [ -z "$TOKENS" ]; then
  TOKENS="$(opt_string mindwtr_cloud_auth_tokens)"
fi
export MINDWTR_CLOUD_AUTH_TOKENS="$TOKENS"
export MINDWTR_CLOUD_AUTH_TOKENS_FILE=""

# --- CORS: new key first, legacy key as fallback, empty = automatic ---
CORS="$(opt_string cors_origin)"
if [ -z "$CORS" ]; then
  CORS="$(opt_string mindwtr_cloud_cors_origin)"
fi
export MINDWTR_CLOUD_CORS_ORIGIN="$CORS"

# --- everything else is fixed automatically ---
export MINDWTR_CLOUD_DATA_DIR="$DATA_DIR"
export MINDWTR_CLOUD_MAX_BODY_BYTES="2000000"
export MINDWTR_CLOUD_MAX_ATTACHMENT_BYTES="50000000"
# Empty = the PWA auto-detects the cloud on its own origin (works with
# Ingress and with direct :8080 access, no CORS needed).
export MINDWTR_DEFAULT_CLOUD_URL=""

mkdir -p "$DATA_DIR" /app/cloud_data /share/mindwtr 2>/dev/null || true
mkdir -p /run/mindwtr-cloud 2>/dev/null || true
chown bun:bun "$DATA_DIR" /run/mindwtr-cloud 2>/dev/null \
  || chown 1000:1000 "$DATA_DIR" /run/mindwtr-cloud 2>/dev/null || true

# --- per-mode status + validation ---
case "$SYNC_MODE" in
  local)
    echo "[mindwtr-entrypoint] sync_mode=local: no sync server started."
    echo "[mindwtr-entrypoint] Data stays in this browser (local folders). Open the web UI and use Mindwtr as-is."
    ;;
  selfhosted)
    if [ -z "$MINDWTR_CLOUD_AUTH_TOKENS" ]; then
      echo "[mindwtr-entrypoint] ERROR: sync_mode=selfhosted but no 'cloud_tokens' set." >&2
      echo "[mindwtr-entrypoint] Set 'cloud_tokens' (20+ chars, e.g. generated with: cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1) then restart." >&2
      echo "[mindwtr-entrypoint] The web UI on :8080 will still start; cloud sync on :8787 stays disabled until a token is set." >&2
    else
      _bad=""
      for t in $(printf '%s' "$MINDWTR_CLOUD_AUTH_TOKENS" | tr ',' ' '); do
        _len=$(printf '%s' "$t" | wc -c)
        _len=$((_len - 1))
        if [ "$_len" -lt 20 ] || [ "$_len" -gt 512 ]; then _bad="yes"; fi
      done
      if [ -n "$_bad" ]; then
        echo "[mindwtr-entrypoint] WARNING: every token must be 20-512 chars; the cloud server will refuse invalid ones." >&2
      fi
      echo "[mindwtr-entrypoint] sync_mode=selfhosted: cloud sync server enabled (data_dir=$DATA_DIR)."
      echo "[mindwtr-entrypoint] In the app: Settings → Sync → Self-Hosted, URL = http://<home-assistant-ip>:8787 (the app appends /v1/data), token = your cloud_tokens value."
    fi
    if [ -n "$MINDWTR_CLOUD_CORS_ORIGIN" ]; then
      echo "[mindwtr-entrypoint] cors_origin=$MINDWTR_CLOUD_CORS_ORIGIN"
    fi
    ;;
  webdav)
    echo "[mindwtr-entrypoint] sync_mode=webdav: no sync server started."
    echo "[mindwtr-entrypoint] Configure WebDAV inside the app: Settings → Sync → WebDAV (server URL, username, password)."
    echo "[mindwtr-entrypoint] Tip: for Nextcloud the URL looks like https://your-server/remote.php/dav/files/USERNAME/Mindwtr"
    ;;
  dropbox)
    echo "[mindwtr-entrypoint] sync_mode=dropbox: no sync server started." >&2
    echo "[mindwtr-entrypoint] NOTE: Dropbox OAuth is NOT available in this web view (upstream limitation: it only exists in the native desktop/mobile builds)." >&2
    echo "[mindwtr-entrypoint] Either use a native Mindwtr app with Dropbox, or switch sync_mode to 'selfhosted' / 'webdav' for browser sync." >&2
    ;;
esac

exec /usr/bin/supervisord -c /etc/supervisord.conf
