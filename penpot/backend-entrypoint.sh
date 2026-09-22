#!/bin/bash
# Penpot backend (Clojure/Java). Waits for postgres + valkey, then runs run.sh.
set -e

# shellcheck disable=SC1091
. /app/penpot-env.sh

if ! command -v valkey-cli >/dev/null 2>&1 && ! command -v redis-cli >/dev/null 2>&1; then
  echo "[backend] FATAL: neither valkey-cli nor redis-cli found" >&2
  exit 1
fi

echo "[backend] waiting for PostgreSQL..."
n=0
until pg_isready -h localhost -p 5432 -U postgres -q 2>/dev/null; do
  sleep 2
  n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then echo "[backend] still waiting for PostgreSQL ($((n * 2))s)..."; fi
done
echo "[backend] PostgreSQL ready."

echo "[backend] waiting for Valkey..."
n=0
until (valkey-cli -h localhost -p 6379 ping 2>/dev/null || redis-cli -h localhost -p 6379 ping 2>/dev/null) | grep -q PONG; do
  sleep 2
  n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then echo "[backend] still waiting for Valkey ($((n * 2))s)..."; fi
done
echo "[backend] Valkey ready."

# Assets dir must exist and be shared with frontend
mkdir -p /opt/data/assets /data/penpot/assets
if [ ! -L /opt/data/assets ] && [ -z "$(ls -A /opt/data/assets 2>/dev/null)" ]; then
  rmdir /opt/data/assets 2>/dev/null || true
  ln -sfn /data/penpot/assets /opt/data/assets
elif [ -d /opt/data/assets ] && [ ! -L /opt/data/assets ]; then
  # merge existing content into persistent dir (first run with COPY template)
  cp -a /opt/data/assets/. /data/penpot/assets/ 2>/dev/null || true
  rm -rf /opt/data/assets
  ln -sfn /data/penpot/assets /opt/data/assets
fi
chown -R penpot:penpot /data/penpot/assets /opt/penpot/backend

echo "[backend] flags: $PENPOT_FLAGS"
echo "[backend] starting..."

cd /opt/penpot/backend
exec su -s /bin/bash penpot -c 'exec bash run.sh'
