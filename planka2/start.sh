#!/bin/bash

# ===============================
# LOAD ENVIRONMENT
# ===============================
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# ===============================
# FORCE SAILS.JS CONFIGURATION
# ===============================
export sails_config__http__trustProxy="true"
export sails_config__sockets__onlyAllowOrigins="*"
export sails_config__session__cookie__secure="false"
export sails_config__session__secret="$SECRET_KEY"

# Force session configuration
export SESSION_COOKIE_SECURE="false"
export SESSION_STORE="memory"

# Force socket configuration
export SOCKETS_ONLY_ALLOW_ORIGINS="*"
export SOCKETS_CORS_ALLOW_ORIGINS="*"
export CORS_ORIGIN="*"

# ===============================
# START PLANKA
# ===============================
echo "Starting Planka with forced configuration..."
echo "trustProxy: $sails_config__http__trustProxy"
echo "socket origins: $sails_config__sockets__onlyAllowOrigins"
echo "session secure: $sails_config__session__cookie__secure"

# Start Planka
npm run start --production
