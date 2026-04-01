#!/usr/bin/env bashio
# Scanopy startup script with bashio configuration

CONFIG_PATH=/data/options.json

# Get database configuration from options using bashio
DB_HOST=$(bashio::config 'DATABASE.db_host')
DB_PORT=$(bashio::config 'DATABASE.db_port')
DB_USER=$(bashio::config 'DATABASE.db_user')
DB_PASSWORD=$(bashio::config 'DATABASE.db_password')
DB_NAME=$(bashio::config 'DATABASE.db_name')

# Build database URL
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Set environment variables for scanopy
export SCANOPY_DATABASE_URL="$DATABASE_URL"
export PORT=60072
export DATA_DIR=/share/scanopy

# Create data directories
mkdir -p /share/scanopy/scans /share/scanopy/db

# Log configuration (without password)
echo "Starting Scanopy with configuration:"
echo "  Database Host: ${DB_HOST}"
echo "  Database Port: ${DB_PORT}"
echo "  Database User: ${DB_USER}"
echo "  Database Name: ${DB_NAME}"
echo "  Port: ${PORT}"
echo "  Data Directory: ${DATA_DIR}"

# Start scanopy server
exec /app/server
