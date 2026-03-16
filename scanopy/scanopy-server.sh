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

echo "PostgreSQL is ready. Starting Scanopy server with Docker..."

# Create daemon config directory
mkdir -p /data/scanopy/daemon_config
mkdir -p /data/scanopy/static

# Start Scanopy server using Docker (original approach)
docker run -d \
    --name scanopy-server \
    -p 60072:60072 \
    -v /data/scanopy:/data \
    -e SCANOPY_LOG_LEVEL="${SCANOPY_LOG_LEVEL:-info}" \
    -e SCANOPY_DATABASE_URL="${SCANOPY_DATABASE_URL}" \
    -e SCANOPY_WEB_EXTERNAL_PATH="${SCANOPY_WEB_EXTERNAL_PATH:-/app/static}" \
    -e SCANOPY_PUBLIC_URL="${SCANOPY_PUBLIC_URL:-http://localhost:60072}" \
    -e SCANOPY_INTEGRATED_DAEMON_URL="${SCANOPY_INTEGRATED_DAEMON_URL:-http://localhost:60073}" \
    --add-host=host.docker.internal:host-gateway \
    ghcr.io/scanopy/scanopy/server:latest

# Keep the container running
tail -f /dev/null
