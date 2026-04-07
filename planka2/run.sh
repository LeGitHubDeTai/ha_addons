#!/usr/bin/env bash
# Planka startup script with bashio configuration

echo "Starting Planka startup script..."
echo "Script is running..."

# Test if bashio is available
echo "Testing bashio..."
which bashio || echo "bashio not found"
bashio --version || echo "bashio version failed"

# Get database configuration from options using bashio
echo "Reading configuration..."
DB_HOST=$(bashio::config 'DATABASE.db_host')
DB_PORT=$(bashio::config 'DATABASE.db_port')
DB_USER=$(bashio::config 'DATABASE.db_user')
DB_PASSWORD=$(bashio::config 'DATABASE.db_password')
DB_NAME=$(bashio::config 'DATABASE.db_name')

# Get admin configuration from options using bashio
ADMIN_EMAIL=$(bashio::config 'ADMIN.email')
ADMIN_PASSWORD=$(bashio::config 'ADMIN.password')
ADMIN_NAME=$(bashio::config 'ADMIN.name')

# Get other configuration
BASE_URL=$(bashio::config 'BASE_URL')
SECRET_KEY=$(bashio::config 'SECRET_KEY')

echo "Configuration read successfully"

# Set environment variables for Planka
export NODE_ENV=production
export PORT=1337
export BASE_URL="${BASE_URL:-/}"

# Database configuration
export DATABASE_HOST="$DB_HOST"
export DATABASE_PORT="$DB_PORT"
export DATABASE_USER="$DB_USER"
export DATABASE_PASSWORD="$DB_PASSWORD"
export DATABASE_NAME="$DB_NAME"
export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Admin configuration
export DEFAULT_ADMIN_EMAIL="$ADMIN_EMAIL"
export DEFAULT_ADMIN_PASSWORD="$ADMIN_PASSWORD"
export DEFAULT_ADMIN_NAME="$ADMIN_NAME"

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

# Log configuration (without password)
echo "Starting Planka with configuration:"
echo "  Database Host: ${DB_HOST}"
echo "  Database Port: ${DB_PORT}"
echo "  Database User: ${DB_USER}"
echo "  Database Name: ${DB_NAME}"
echo "  Admin Email: ${ADMIN_EMAIL}"
echo "  Base URL: ${BASE_URL}"
echo "  Port: ${PORT}"

# Check if Node.js and app files exist
echo "Checking Node.js and app files..."
node --version
ls -la /app/app.js

# Initialize database and start Planka
cd /app
echo "Initializing database..."

# Test database connection first
echo "Testing database connection..."
node -e "
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
pool.query('SELECT NOW()')
  .then(res => {
    console.log('Database connection successful:', res.rows[0]);
    process.exit(0);
  })
  .catch(err => {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  });
"

if [ $? -ne 0 ]; then
    echo "Database connection failed. Please check your database configuration."
    echo "DATABASE_URL: ${DATABASE_URL}"
    exit 1
fi

echo "Database connection OK, initializing database..."
node db/init.js
echo "Database initialization completed."

echo "Creating admin user if not exists..."
npm run db:create-admin-user || echo "Admin user may already exist"

echo "Starting Planka server..."
echo "Server will be available at http://localhost:${PORT}${BASE_URL}"
exec npm start --prod
