#!/bin/bash
set -e

# Initialize PostgreSQL data directory if it doesn't exist
if [ ! -d "/data/scanopy/postgres_data/base" ]; then
    echo "Initializing PostgreSQL data directory..."
    initdb -D /data/scanopy/postgres_data -U postgres
    
    # Create PostgreSQL configuration
    cat >> /data/scanopy/postgres_data/postgresql.conf << EOF
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
EOF

    # Start PostgreSQL temporarily to create database
    pg_ctl -D /data/scanopy/postgres_data -l /var/log/scanopy/postgres.log start &
    
    # Wait for PostgreSQL to start
    sleep 10
    
    # Create the scanopy database
    createdb -h localhost -U postgres scanopy
    
    # Stop PostgreSQL
    pg_ctl -D /data/scanopy/postgres_data -m fast stop
fi

# Set proper permissions
chown -R postgres:postgres /data/scanopy/postgres_data
chmod 700 /data/scanopy/postgres_data

echo "PostgreSQL initialization complete"
