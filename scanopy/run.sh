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

# Read configuration from Home Assistant environment variables
LOG_LEVEL="${log_level:-info}"
DATABASE_URL="${database_url:-}"
PUBLIC_URL="${public_url:-http://localhost:60072}"
ENABLE_DOCKER_DISCOVERY="${enable_docker_discovery:-true}"
INITIAL_INTERVAL="${scan_intervals_initial:-5m}"
RECURRING_INTERVAL="${scan_intervals_recurring:-1h}"

# Start daemon and check which port it uses
echo "Starting daemon..."
echo "Checking available ports before daemon starts..."
netstat -tlnp | grep -E ":(6007[0-9]|8080|3000|5173)" || echo "No conflicting ports found"
/opt/scanopy-daemon &
sleep 3
echo "Checking ports after daemon starts..."
netstat -tlnp | grep -E ":(6007[0-9]|8080|3000|5173)" || echo "Daemon port not found in listening state"

# Start nginx on port 60072 (external access)
echo "Starting nginx on port 60072..."
nginx -g "daemon off;" &

# Wait for processes
wait
