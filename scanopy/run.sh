#!/bin/bash
set -euo pipefail

echo "=== Scanopy Addon Starting ==="

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
    # Stop Scanopy server container
    docker stop scanopy-server || true
    docker rm scanopy-server || true
    # Kill background processes
    jobs -p | xargs -r kill
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Create necessary directories
mkdir -p /data/scanopy/daemon_config
mkdir -p /data/scanopy/static

# Start nginx in background
echo "Starting nginx..."
nginx -g "daemon off;" &

# Start Scanopy server container
echo "Starting Scanopy server container..."

# Remove existing container if it exists
docker stop scanopy-server 2>/dev/null || true
docker rm scanopy-server 2>/dev/null || true

docker run -d \
    --name scanopy-server \
    -p 60072:60072 \
    -v /data/scanopy:/data \
    -e SCANOPY_LOG_LEVEL="${SCANOPY_LOG_LEVEL:-info}" \
    -e SCANOPY_DATABASE_URL="${SCANOPY_DATABASE_URL:-${DATABASE_URL:-postgresql://user:password@host:port/database}}" \
    -e SCANOPY_WEB_EXTERNAL_PATH="${SCANOPY_WEB_EXTERNAL_PATH:-/app/static}" \
    -e SCANOPY_PUBLIC_URL="${SCANOPY_PUBLIC_URL:-http://localhost:60072}" \
    -e SCANOPY_INTEGRATED_DAEMON_URL="${SCANOPY_INTEGRATED_DAEMON_URL:-http://localhost:60073}" \
    --add-host=host.docker.internal:host-gateway \
    --restart unless-stopped \
    ghcr.io/scanopy/scanopy/server:latest

# Wait for Scanopy server to be ready
echo "Waiting for Scanopy server to be ready..."
sleep 15

# Start Scanopy daemon (native binary)
echo "Starting Scanopy daemon..."
/opt/scanopy-daemon \
    --server-url="${SCANOPY_SERVER_URL:-http://127.0.0.1:60072}" \
    --config-dir="/data/scanopy/daemon_config" \
    --log-level="${SCANOPY_LOG_LEVEL:-info}" &

echo "=== Scanopy Addon Started Successfully ==="
echo "Web UI: ${SCANOPY_PUBLIC_URL:-http://localhost:60072}"
echo "Daemon API: ${SCANOPY_INTEGRATED_DAEMON_URL:-http://localhost:60073}"
echo "Database: ${SCANOPY_DATABASE_URL:-${DATABASE_URL:-Not configured}}"

# Keep the container running as PID 1
wait
