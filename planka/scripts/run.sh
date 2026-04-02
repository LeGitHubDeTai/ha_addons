#!/bin/bash

# Set environment variables from configuration
export NODE_ENV=production
export PORT=1337
export BASE_URL="${BASE_URL:-/}"

# Database configuration
export DATABASE_HOST="${DATABASE_DB_HOST:-postgres}"
export DATABASE_PORT="${DATABASE_DB_PORT:-5432}"
export DATABASE_USER="${DATABASE_DB_USER:-planka}"
export DATABASE_PASSWORD="${DATABASE_DB_PASSWORD:-homeassistant}"
export DATABASE_NAME="${DATABASE_DB_NAME:-planka}"
export DATABASE_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}"

# Admin configuration
export ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-homeassistant}"
export ADMIN_NAME="${ADMIN_NAME:-Admin}"

# Secret key
if [ -n "$SECRET_KEY" ]; then
    export SECRET_KEY="$SECRET_KEY"
else
    # Generate a random secret key if not provided
    export SECRET_KEY=$(openssl rand -hex 32)
fi

# Create necessary directories
mkdir -p /data/user-avatars /data/project-background-images /data/attachments

# Set permissions
chown -R root:root /app /data
chmod -R 755 /data

# Start Planka
cd /app
exec npm start
