#!/bin/bash
# Penpot exporter (Node + Chromium). Waits for valkey + backend.
set -e

# shellcheck disable=SC1091
. /app/penpot-env.sh

# PENPOT_REDIS_URI is already set by penpot-env.sh (embedded or external)
if command -v valkey-cli >/dev/null 2>&1; then
  REDIS_CLI="valkey-cli"
else
  REDIS_CLI="redis-cli"
fi

echo "[exporter] waiting for Valkey at ${PENPOT_REDIS_HOST}:${PENPOT_REDIS_PORT}..."
n=0
until "$REDIS_CLI" -h "$PENPOT_REDIS_HOST" -p "$PENPOT_REDIS_PORT" ping 2>/dev/null | grep -q PONG; do
  sleep 2
  n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then echo "[exporter] still waiting for Valkey ($((n * 2))s)..."; fi
done
echo "[exporter] Valkey ready."

echo "[exporter] waiting for backend..."
n=0
until curl -fsS -o /dev/null http://localhost:6060/readyz 2>/dev/null; do
  sleep 2
  n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then echo "[exporter] still waiting for backend ($((n * 2))s)..."; fi
done
echo "[exporter] backend ready."

export PENPOT_INTERNAL_URI="http://localhost:8080"

echo "[exporter] starting..."
cd /opt/penpot/exporter
exec su -s /bin/bash penpot -c 'exec node app.js'
