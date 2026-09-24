#!/bin/sh
# Runs mindwtr-cloud. Invoked by supervisord AFTER entrypoint.sh has exported
# SYNC_MODE and the MINDWTR_* env vars.
# The cloud server only runs in sync_mode=selfhosted with a token configured.
# In every other mode this program idles so the web UI stays up on its own.
set -eu

MODE="${SYNC_MODE:-local}"

if [ "$MODE" != "selfhosted" ]; then
  case "$MODE" in
    local) echo "[mindwtr-cloud-run] sync_mode=local: cloud server disabled, local folders only." ;;
    webdav) echo "[mindwtr-cloud-run] sync_mode=webdav: cloud server disabled, sync is handled by your WebDAV endpoint." ;;
    dropbox) echo "[mindwtr-cloud-run] sync_mode=dropbox: cloud server disabled (Dropbox OAuth needs a native app build)." ;;
    *) echo "[mindwtr-cloud-run] cloud server disabled (sync_mode=$MODE)." ;;
  esac
  # Idle forever: keeps supervisord happy (RUNNING) without log spam.
  while true; do sleep 3600; done
fi

if [ -z "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ] && [ -z "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:-}" ]; then
  echo "[mindwtr-cloud-run] sync_mode=selfhosted but no token configured; cloud server disabled until 'cloud_tokens' is set." >&2
  while true; do sleep 3600; done
fi

DATA_DIR="${MINDWTR_CLOUD_DATA_DIR:-/share/mindwtr}"
mkdir -p "$DATA_DIR" /run/mindwtr-cloud 2>/dev/null || true
chown bun:bun "$DATA_DIR" 2>/dev/null || chown 1000:1000 "$DATA_DIR" 2>/dev/null || true

# --- Guard for `install: can't stat ...` ---
# Upstream docker/cloud/entrypoint.sh executes:
#   install -o bun -g bun -m 0400 "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" /run/mindwtr-cloud/auth-tokens
# whenever MINDWTR_CLOUD_AUTH_TOKENS_FILE is non-empty. A path that does not
# exist makes the cloud process exit (code 1) in a supervisord restart loop.
# Policy: prefer the inline token and unset FILE; keep FILE only when it
# points to an existing readable file.
if [ -n "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ]; then
  unset MINDWTR_CLOUD_AUTH_TOKENS_FILE || true
elif [ -n "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:-}" ]; then
  if [ ! -f "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" ] || [ ! -r "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" ]; then
    echo "[mindwtr-cloud-run] MINDWTR_CLOUD_AUTH_TOKENS_FILE=$MINDWTR_CLOUD_AUTH_TOKENS_FILE is missing/unreadable; unsetting it." >&2
    unset MINDWTR_CLOUD_AUTH_TOKENS_FILE || true
  fi
fi

# Backwards-compat: very old images dropped a token file at the legacy
# /app/cloud_data/auth-tokens path without setting env vars.
if [ -z "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ] && [ -z "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:-}" ]; then
  if [ -f /app/cloud_data/auth-tokens ] && [ -s /app/cloud_data/auth-tokens ]; then
    echo "[mindwtr-cloud-run] using legacy token file /app/cloud_data/auth-tokens" >&2
    export MINDWTR_CLOUD_AUTH_TOKENS_FILE="/app/cloud_data/auth-tokens"
  fi
fi

exec /usr/local/bin/mindwtr-cloud-entrypoint bun run --filter mindwtr-cloud start -- --host 0.0.0.0 --port 8787
