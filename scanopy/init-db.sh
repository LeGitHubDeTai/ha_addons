#!/bin/bash
set -euo pipefail

echo "Initializing Scanopy database..."

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -U postgres; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

# Check if database exists, if not create it
if ! su postgres -c "psql -h localhost -p 5432 -U postgres -l" | grep -q scanopy; then
    echo "Creating scanopy database..."
    su postgres -c "createdb -h localhost -p 5432 scanopy"
fi

echo "Database initialization completed."
