#!/bin/bash

# Simple startup script for Scanopy addon

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
    killall scanopy-daemon 2>/dev/null || true
    nginx -s quit 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start nginx in background
nginx

# Start scanopy daemon
echo "Starting Scanopy daemon..."
# Set required environment variables for daemon
export SCANOPY_DAEMON_URL="http://localhost:60073"
export SCANOPY_SERVER_URL="http://localhost:60072"
export SCANOPY_LOG_LEVEL="${SCANOPY_LOG_LEVEL:-info}"
export DATABASE_URL="${DATABASE_URL:-}"

/opt/scanopy-daemon &

# Wait for processes
wait
