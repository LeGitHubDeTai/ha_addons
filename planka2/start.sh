#!/bin/bash

# ===============================
# PLANKA START.SH (OFFICIEL COMPATIBLE)
# ===============================

# Set production environment
export NODE_ENV=production

# Load secrets from files if they exist
if [ -f "/run/secrets/SECRET_KEY" ]; then
    export SECRET_KEY=$(cat /run/secrets/SECRET_KEY)
fi

if [ -f "/run/secrets/DATABASE_URL" ]; then
    export DATABASE_URL=$(cat /run/secrets/DATABASE_URL)
fi

# Start outgoing proxy if needed
if [ -n "$OUTGOING_BLOCKED_HOSTS" ] || [ -n "$OUTGOING_BLOCKED_IPS" ] || [ -n "$OUTGOING_ALLOWED_HOSTS" ] || [ -n "$OUTGOING_ALLOWED_IPS" ]; then
    echo "Starting outgoing proxy..."
    /usr/sbin/squid -f /etc/squid/squid.conf -N &
    sleep 2
fi

# Initialize database
if [ -f "./server/db/init.js" ]; then
    echo "Initializing database..."
    cd server && node ./db/init.js && cd ..
fi

# Start Planka
echo "Starting Planka..."
cd server && exec npm run start:prod
