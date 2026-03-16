#!/bin/bash
set -e

# Initialize PostgreSQL data directory if it doesn't exist
if [ ! -d "/data/scanopy/postgres_data/base" ]; then
    echo "Initializing PostgreSQL data directory..."
    initdb -D /data/scanopy/postgres_data -U postgres
    
    # Start PostgreSQL temporarily to create database
    pg_ctl -D /data/scanopy/postgres_data -l /var/log/postgres.log start &
    
    # Wait for PostgreSQL to start
    sleep 10
    
    # Create the scanopy database
    createdb -h localhost -U postgres scanopy
    
    # Stop PostgreSQL
    pg_ctl -D /data/scanopy/postgres_data -m fast stop
fi

# Set proper permissions
chown -R postgres:postgres /data/scanopy/postgres_data
chmod 700 /data/scanopy/postgres_data

# Create daemon config directory if it doesn't exist
mkdir -p /data/scanopy/daemon_config

# Create static files directory if it doesn't exist
mkdir -p /data/scanopy/static

# Start PostgreSQL in background
su postgres -c "pg_ctl -D /data/scanopy/postgres_data -l /var/log/postgres.log start"

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -U postgres; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

echo "PostgreSQL is ready. Starting Scanopy services..."

# Start Scanopy daemon in background
docker run -d \
    --name scanopy-daemon \
    --network host \
    --privileged \
    -v /data/scanopy/daemon_config:/root/.config/daemon \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -e SCANOPY_LOG_LEVEL="${SCANOPY_LOG_LEVEL:-info}" \
    -e SCANOPY_SERVER_URL="${SCANOPY_SERVER_URL:-http://127.0.0.1:60072}" \
    ghcr.io/scanopy/scanopy/daemon:latest

# Start Scanopy server in background
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

# Start nginx
nginx -g "daemon off;"
