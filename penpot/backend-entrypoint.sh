#!/bin/bash
# Penpot backend (Clojure/Java). Waits for external PostgreSQL + Valkey, then runs run.sh.
set -e

# shellcheck disable=SC1091
. /app/penpot-env.sh

if [ -z "$PENPOT_DB_HOST" ]; then
  echo "[backend] FATAL: DATABASE.db_host is not configured. Set your external PostgreSQL host in the add-on options." >&2
  exit 1
fi

# Pick a redis CLI (valkey-cli preferred, redis-cli fallback)
if command -v valkey-cli >/dev/null 2>&1; then
  REDIS_CLI="valkey-cli"
elif command -v redis-cli >/dev/null 2>&1; then
  REDIS_CLI="redis-cli"
else
  echo "[backend] FATAL: neither valkey-cli nor redis-cli found" >&2
  exit 1
fi

echo "[backend] waiting for PostgreSQL at ${PENPOT_DB_HOST}:${PENPOT_DB_PORT}..."
n=0
until pg_isready -h "$PENPOT_DB_HOST" -p "$PENPOT_DB_PORT" -U "$PENPOT_DB_USER" -q 2>/dev/null; do
  sleep 2
  n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then echo "[backend] still waiting for PostgreSQL ${PENPOT_DB_HOST}:${PENPOT_DB_PORT} ($((n * 2))s)... check host/credentials/firewall."; fi
done
echo "[backend] PostgreSQL ready."

echo "[backend] waiting for Valkey at ${PENPOT_REDIS_HOST}:${PENPOT_REDIS_PORT}..."
n=0
until "$REDIS_CLI" -h "$PENPOT_REDIS_HOST" -p "$PENPOT_REDIS_PORT" ping 2>/dev/null | grep -q PONG; do
  sleep 2
  n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then echo "[backend] still waiting for Valkey ${PENPOT_REDIS_HOST}:${PENPOT_REDIS_PORT} ($((n * 2))s)..."; fi
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
