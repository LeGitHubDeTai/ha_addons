#!/bin/bash
set -e

# Initialize PostgreSQL data directory if it doesn't exist
if [ ! -d "/data/scanopy/postgres_data/base" ]; then
    echo "Initializing PostgreSQL data directory..."
    initdb -D /data/scanopy/postgres_data -U postgres
    
    # Start PostgreSQL temporarily to create database
    pg_ctl -D /data/scanopy/postgres_data -l /var/log/postgres.log start
    
    # Wait for PostgreSQL to start
    sleep 5
    
    # Create the scanopy database
    createdb -h localhost -U postgres scanopy
    
    # Stop PostgreSQL
    pg_ctl -D /data/scanopy/postgres_data -m fast stop
fi

# Set proper permissions
chown -R postgres:postgres /data/scanopy/postgres_data
chmod 700 /data/scanopy/postgres_data

# Create daemon config directory if it doesn't exist
mkdir -p /data/scanopy/daemon_config

# Create static files directory if it doesn't exist
mkdir -p /data/scanopy/static

echo "Scanopy initialization complete. Starting services..."
