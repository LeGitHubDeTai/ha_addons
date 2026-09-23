#!/bin/sh
set -eu

mkdir -p /app/cloud_data

if [ -n "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ]; then
  printf '%s' "$MINDWTR_CLOUD_AUTH_TOKENS" > /app/cloud_data/auth-tokens
  chmod 600 /app/cloud_data/auth-tokens
fi

exec /usr/local/bin/mindwtr-cloud-entrypoint bun run --filter mindwtr-cloud start -- --host 0.0.0.0 --port 8787
