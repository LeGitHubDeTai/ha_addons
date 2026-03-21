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

# Read configuration from Home Assistant
LOG_LEVEL=$(bashio::config log_level)
DATABASE_URL=$(bashio::config database_url)
PUBLIC_URL=$(bashio::config public_url)
ENABLE_DOCKER_DISCOVERY=$(bashio::config enable_docker_discovery)
INITIAL_INTERVAL=$(bashio::config 'scan_intervals.initial')
RECURRING_INTERVAL=$(bashio::config 'scan_intervals.recurring')

# Start nginx in background
nginx

# Start scanopy daemon with configuration from config.yaml
echo "Starting Scanopy daemon..."
echo "Log level: $LOG_LEVEL"
echo "Database URL: ${DATABASE_URL:0:20}..." # Show only first 20 chars for security
echo "Public URL: $PUBLIC_URL"
echo "Docker discovery: $ENABLE_DOCKER_DISCOVERY"

# Set required environment variables for daemon
export SCANOPY_DAEMON_URL="http://localhost:60073"
export SCANOPY_SERVER_URL="http://localhost:60072"
export SCANOPY_PUBLIC_URL="$PUBLIC_URL"
export SCANOPY_LOG_LEVEL="$LOG_LEVEL"
export DATABASE_URL="$DATABASE_URL"
export SCANOPY_ENABLE_DOCKER_DISCOVERY="$ENABLE_DOCKER_DISCOVERY"
export SCANOPY_INITIAL_INTERVAL="$INITIAL_INTERVAL"
export SCANOPY_RECURRING_INTERVAL="$RECURRING_INTERVAL"

/opt/scanopy-daemon &

# Wait for processes
wait
