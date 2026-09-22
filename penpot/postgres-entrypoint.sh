#!/bin/bash
# PostgreSQL for Penpot (supervisord program, stays in foreground).
set -e

PGDATA="/data/penpot/postgres"
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

# shellcheck disable=SC1091
. /app/penpot-env.sh

export PGPASSWORD="$PENPOT_DB_PASSWORD"

# --- Init cluster if needed ---
if [ ! -f "$PGDATA/PG_VERSION" ]; then
  echo "[postgres] initdb..."
  su -s /bin/bash postgres -c "/usr/lib/postgresql/*/bin/initdb -D $PGDATA -E UTF8 --data-checksums"
  echo "listen_addresses = 'localhost'" >> "$PGDATA/postgresql.conf"
  echo "port = 5432" >> "$PGDATA/postgresql.conf"
fi

# --- Temp start to ensure role/database/password ---
echo "[postgres] temp start for setup..."
su -s /bin/bash postgres -c "/usr/lib/postgresql/*/bin/pg_ctl -D $PGDATA -o '-c config_file=$PGDATA/postgresql.conf' -w start"

setup_done=false
for i in $(seq 1 30); do
  if su -s /bin/bash postgres -c "psql -h localhost -U postgres -tc \"SELECT 1\"" 2>/dev/null | grep -q 1; then
    setup_done=true
    break
  fi
  sleep 1
done

if [ "$setup_done" = "true" ]; then
  # Role penpot (create or sync password)
  if ! su -s /bin/bash postgres -c "psql -h localhost -U postgres -tc \"SELECT 1 FROM pg_roles WHERE rolname='penpot'\"" | grep -q 1; then
    echo "[postgres] creating role + database..."
    su -s /bin/bash postgres -c "psql -h localhost -U postgres -v ON_ERROR_STOP=1 -c \"CREATE USER penpot WITH PASSWORD '$PENPOT_DB_PASSWORD';\""
    su -s /bin/bash postgres -c "psql -h localhost -U postgres -v ON_ERROR_STOP=1 -c \"CREATE DATABASE penpot OWNER penpot;\""
    su -s /bin/bash postgres -c "psql -h localhost -U postgres -v ON_ERROR_STOP=1 -c \"GRANT ALL PRIVILEGES ON DATABASE penpot TO penpot;\""
  else
    echo "[postgres] syncing role password..."
    su -s /bin/bash postgres -c "psql -h localhost -U postgres -v ON_ERROR_STOP=1 -c \"ALTER USER penpot WITH PASSWORD '$PENPOT_DB_PASSWORD';\""
  fi
else
  echo "[postgres] WARNING: setup connection failed, continuing anyway"
fi

echo "[postgres] stopping temp server..."
su -s /bin/bash postgres -c "/usr/lib/postgresql/*/bin/pg_ctl -D $PGDATA -m fast stop" || true

# --- Run in foreground (supervisord manages restarts) ---
echo "[postgres] starting foreground..."
exec su -s /bin/bash postgres -c "exec /usr/lib/postgresql/*/bin/postgres -D $PGDATA -c config_file=$PGDATA/postgresql.conf"
