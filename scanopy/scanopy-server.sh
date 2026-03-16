#!/bin/bash
set -e

# Initialize database
/scripts/init-db.sh

# Start PostgreSQL
echo "Starting PostgreSQL..."
su postgres -c "pg_ctl -D /data/scanopy/postgres_data -l /var/log/scanopy/postgres.log start"

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -U postgres; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

echo "PostgreSQL is ready. Starting Scanopy server..."

# Create daemon config directory
mkdir -p /data/scanopy/daemon_config
mkdir -p /data/scanopy/static

# Start Scanopy server
exec /opt/scanopy/scanopy-server \
    --log-level="${SCANOPY_LOG_LEVEL:-info}" \
    --database-url="${SCANOPY_DATABASE_URL}" \
    --web-external-path="${SCANOPY_WEB_EXTERNAL_PATH:-/app/static}" \
    --public-url="${SCANOPY_PUBLIC_URL:-http://localhost:60072}" \
    --integrated-daemon-url="${SCANOPY_INTEGRATED_DAEMON_URL:-http://localhost:60073}" \
    --bind-address="0.0.0.0" \
    --port=60072
