#!/bin/bash
set -euo pipefail

echo "=== Scanopy Addon Starting ==="

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
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

# Start Scanopy server directly
echo "Starting Scanopy server..."
/opt/scanopy-server \
    --database-url="${SCANOPY_DATABASE_URL:-${DATABASE_URL:-postgresql://user:password@host:port/database}}" \
    --web-external-path="${SCANOPY_WEB_EXTERNAL_PATH:-/app/static}" \
    --public-url="${SCANOPY_PUBLIC_URL:-http://localhost:60072}" \
    --integrated-daemon-url="${SCANOPY_INTEGRATED_DAEMON_URL:-http://localhost:60073}" \
    --log-level="${SCANOPY_LOG_LEVEL:-info}" &

# Wait for Scanopy server to be ready
echo "Waiting for Scanopy server to be ready..."
sleep 15

# Start Scanopy daemon
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
