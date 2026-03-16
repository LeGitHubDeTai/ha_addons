#!/bin/bash
set -e

# Wait a bit for server to start
sleep 10

echo "Starting Scanopy daemon..."

# Start Scanopy daemon using local binary
exec /opt/scanopy/scanopy-daemon \
    --server-url="${SCANOPY_SERVER_URL:-http://127.0.0.1:60072}" \
    --config-dir="/data/scanopy/daemon_config" \
    --log-level="${SCANOPY_LOG_LEVEL:-info}"
