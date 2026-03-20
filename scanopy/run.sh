#!/usr/bin/env bashio
set -euo pipefail

bashio::log.info "Starting Scanopy addon..."

# Initialize database
/scripts/init-db.sh

# Start PostgreSQL
bashio::log.info "Starting PostgreSQL..."
su postgres -c "pg_ctl -D /data/scanopy/postgres_data -l /var/log/scanopy/postgres.log start"

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -U postgres; do
    bashio::log.info "Waiting for PostgreSQL..."
    sleep 2
done

bashio::log.info "PostgreSQL is ready. Starting Scanopy server with Docker..."

# Create daemon config directory
mkdir -p /data/scanopy/daemon_config
mkdir -p /data/scanopy/static

# Get configuration from Home Assistant options
SCANOPY_LOG_LEVEL=$(bashio::config 'log_level')
SCANOPY_PUBLIC_URL=$(bashio::config 'public_url')
ENABLE_DOCKER_DISCOVERY=$(bashio::config 'enable_docker_discovery')

# Start Scanopy server using Docker
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

# Wait a bit for server to start
sleep 10

bashio::log.info "Starting Scanopy daemon..."

# Start Scanopy daemon using local binary in background
/opt/scanopy/scanopy-daemon \
    --server-url="${SCANOPY_SERVER_URL:-http://127.0.0.1:60072}" \
    --config-dir="/data/scanopy/daemon_config" \
    --log-level="${SCANOPY_LOG_LEVEL:-info}" &

# Keep the container running and monitor processes
while true; do
    # Check if PostgreSQL is running
    if ! pg_isready -h localhost -p 5432 -U postgres; then
        bashio::log.error "PostgreSQL is not running, restarting..."
        su postgres -c "pg_ctl -D /data/scanopy/postgres_data -l /var/log/scanopy/postgres.log start"
    fi
    
    # Check if Scanopy server container is running
    if ! docker ps | grep scanopy-server; then
        bashio::log.error "Scanopy server container is not running, restarting..."
        docker start scanopy-server
    fi
    
    # Check if daemon is running
    if ! pgrep -f scanopy-daemon > /dev/null; then
        bashio::log.error "Scanopy daemon is not running, restarting..."
        /opt/scanopy/scanopy-daemon \
            --server-url="${SCANOPY_SERVER_URL:-http://127.0.0.1:60072}" \
            --config-dir="/data/scanopy/daemon_config" \
            --log-level="${SCANOPY_LOG_LEVEL:-info}" &
    fi
    
    sleep 30
done
