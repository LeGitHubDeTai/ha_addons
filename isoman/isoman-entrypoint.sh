#!/bin/bash

# Set timezone
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
fi

# Create ISO storage directory if it doesn't exist
ISO_STORAGE_PATH="${ISO_STORAGE_PATH:-/data/isoman}"
mkdir -p "$ISO_STORAGE_PATH"

# Set environment variables for Isoman
export DATA_DIR="$ISO_STORAGE_PATH"
export PORT="8080"
export CORS_ORIGINS="http://localhost:3000,http://localhost:5173,http://localhost:8080"

# Configure worker count from addon config
if [ -n "$MAX_CONCURRENT_DOWNLOADS" ]; then
    export WORKER_COUNT="$MAX_CONCURRENT_DOWNLOADS"
else
    export WORKER_COUNT="3"
fi

# Configure logging
if [ -n "$LOG_LEVEL" ]; then
    export LOG_LEVEL="$LOG_LEVEL"
else
    export LOG_LEVEL="info"
fi

if [ -n "$LOG_FORMAT" ]; then
    export LOG_FORMAT="$LOG_FORMAT"
else
    export LOG_FORMAT="text"
fi

# Database configuration
export DB_PATH=""  # Will use default in data directory

# Additional environment variables from config
if [ -n "$ENV_VARS_LIST" ]; then
    echo "$ENV_VARS_LIST" | tr ',' '\n' | while IFS= read -r line; do
        if [ -n "$line" ]; then
            export "$line"
        fi
    done
fi

# Start Isoman frontend
cd /opt/isoman/ui
exec npm run serve -- --port 8080 --host 0.0.0.0
