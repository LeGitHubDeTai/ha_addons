#!/bin/sh
# Runs mindwtr-cloud. Invoked by supervisord AFTER entrypoint.sh has exported
# the HA options as MINDWTR_* env vars.
set -eu

DATA_DIR="${MINDWTR_CLOUD_DATA_DIR:-/share/mindwtr}"
mkdir -p "$DATA_DIR" /run/mindwtr-cloud 2>/dev/null || true
chown bun:bun "$DATA_DIR" 2>/dev/null || chown 1000:1000 "$DATA_DIR" 2>/dev/null || true

# --- Fix for `install: can't stat '/app/cloud_data/auth-tokens'` ---
# Upstream docker/cloud/entrypoint.sh executes:
#   install -o bun -g bun -m 0400 "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" /run/mindwtr-cloud/auth-tokens
# whenever MINDWTR_CLOUD_AUTH_TOKENS_FILE is non-empty. The old image set it
# unconditionally to /app/cloud_data/auth-tokens, so with no token configured
# the file did not exist and the cloud process exited (code 1) in a
# supervisord FATAL restart loop while nginx stayed up.
#
# Policy here:
# - If inline MINDWTR_CLOUD_AUTH_TOKENS is set, it is sufficient: unset the
#   FILE variable so upstream never tries to copy a (possibly stale) file.
# - If only FILE is set, keep it only when it points to an existing readable
#   file; otherwise unset it so the server fails with its own clear
#   "missing token" message instead of the cryptic install(1) error.
if [ -n "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ]; then
  unset MINDWTR_CLOUD_AUTH_TOKENS_FILE || true
elif [ -n "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:-}" ]; then
  if [ ! -f "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" ] || [ ! -r "$MINDWTR_CLOUD_AUTH_TOKENS_FILE" ]; then
    echo "[mindwtr-cloud-run] MINDWTR_CLOUD_AUTH_TOKENS_FILE=$MINDWTR_CLOUD_AUTH_TOKENS_FILE is missing/unreadable; unsetting it." >&2
    unset MINDWTR_CLOUD_AUTH_TOKENS_FILE || true
  fi
fi

# Backwards-compat: very old configs may have dropped a token file at the
# legacy /app/cloud_data/auth-tokens path without setting env vars.
if [ -z "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ] && [ -z "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:-}" ]; then
  if [ -f /app/cloud_data/auth-tokens ] && [ -s /app/cloud_data/auth-tokens ]; then
    echo "[mindwtr-cloud-run] using legacy token file /app/cloud_data/auth-tokens" >&2
    export MINDWTR_CLOUD_AUTH_TOKENS_FILE="/app/cloud_data/auth-tokens"
  fi
fi

if [ -z "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ] && [ -z "${MINDWTR_CLOUD_AUTH_TOKENS_FILE:-}" ]; then
  echo "[mindwtr-cloud-run] ERROR: no cloud auth token. Set 'mindwtr_cloud_auth_tokens' in add-on options (min 20 chars)." >&2
  echo "[mindwtr-cloud-run] The server will now start and report its own error; the web UI on :8080 keeps running." >&2
fi

# Extra CLI args from `cmd_line_args` option (already exported by entrypoint.sh).
# Word-splitting is intentional here.
# shellcheck disable=SC2086
if [ -n "${MINDWTR_CMD_LINE_ARGS:-}" ]; then
  # shellcheck disable=SC2086
  exec /usr/local/bin/mindwtr-cloud-entrypoint bun run --filter mindwtr-cloud start -- --host 0.0.0.0 --port 8787 $MINDWTR_CMD_LINE_ARGS
else
  exec /usr/local/bin/mindwtr-cloud-entrypoint bun run --filter mindwtr-cloud start -- --host 0.0.0.0 --port 8787
fi
