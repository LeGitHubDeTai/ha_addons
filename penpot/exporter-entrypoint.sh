#!/bin/bash
# Penpot exporter (Node + Chromium). Waits for valkey + backend.
set -e

# shellcheck disable=SC1091
. /app/penpot-env.sh

echo "[exporter] waiting for Valkey..."
for i in $(seq 1 60); do
  if (valkey-cli -h localhost -p 6379 ping 2>/dev/null || redis-cli -h localhost -p 6379 ping 2>/dev/null) | grep -q PONG; then
    break
  fi
  sleep 1
done

echo "[exporter] waiting for backend..."
for i in $(seq 1 120); do
  if curl -fsS -o /dev/null http://localhost:6060/readyz 2>/dev/null; then
    break
  fi
  sleep 2
done

export PENPOT_INTERNAL_URI="http://localhost:8080"
export PENPOT_REDIS_URI="redis://localhost:6379/0"

echo "[exporter] starting..."
cd /opt/penpot/exporter
exec su -s /bin/bash penpot -c 'exec node app.js'
