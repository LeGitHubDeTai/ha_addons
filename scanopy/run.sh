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
/opt/scanopy-daemon &

# Wait for processes
wait
