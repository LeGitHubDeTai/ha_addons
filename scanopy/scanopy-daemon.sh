#!/bin/bash
set -e

# Wait a bit for server to start
sleep 5

echo "Starting Scanopy daemon..."

# Start Scanopy daemon
exec /opt/scanopy/scanopy-daemon \
    --log-level="${SCANOPY_LOG_LEVEL:-info}" \
    --server-url="${SCANOPY_SERVER_URL:-http://127.0.0.1:60072}" \
    --config-dir="/data/scanopy/daemon_config" \
    --bind-address="0.0.0.0" \
    --port=60073
