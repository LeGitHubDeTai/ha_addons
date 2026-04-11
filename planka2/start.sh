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
# DEBUG CONFIGURATION
# ===============================
echo "=== PLANKA STARTUP DEBUG ==="
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"
echo "EXPLICIT_HOST: $EXPLICIT_HOST"
echo "TRUST_PROXY: $TRUST_PROXY"
echo "DATABASE_URL: ${DATABASE_URL:0:50}..."
echo "SECRET_KEY: ${SECRET_KEY:0:10}..."
echo "sails_config__http__trustProxy: $sails_config__http__trustProxy"
echo "sails_config__sockets__onlyAllowOrigins: $sails_config__sockets__onlyAllowOrigins"
echo "sails_config__session__cookie__secure: $sails_config__session__cookie__secure"
echo "============================="

# ===============================
# HEALTH CHECK
# ===============================
echo "Checking database connection..."
if command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL client available"
else
    echo "PostgreSQL client not found"
fi

echo "Checking Node.js version..."
node --version

echo "Checking npm version..."
npm --version

echo "Checking Planka files..."
ls -la app.js 2>/dev/null || echo "app.js not found"
ls -la package.json 2>/dev/null || echo "package.json not found"

echo "Checking port availability..."
if netstat -tuln | grep -q ":1337 "; then
    echo "Port 1337 is already in use"
else
    echo "Port 1337 is available"
fi

echo "Checking environment variables..."
env | grep -E "(NODE_ENV|PORT|DATABASE_URL|SECRET_KEY)" | head -10

# ===============================
# START PLANKA WITH HEALTH MONITORING
# ===============================
echo "Starting Planka with forced configuration..."

# Start Planka in background for monitoring
npm run start --production &
PLANKA_PID=$!

# Wait for startup and monitor
echo "Planka PID: $PLANKA_PID"
echo "Waiting for Planka to start..."

for i in {1..30}; do
    if kill -0 $PLANKA_PID 2>/dev/null; then
        echo "Planka process running ($i/30 seconds)"
        sleep 1
    else
        echo "Planka process died!"
        echo "Exit status: $?"
        exit 1
    fi
done

echo "Planka should be ready now. Checking health..."
curl -f http://localhost:1337/health 2>/dev/null && echo "Health check passed" || echo "Health check failed"

# Bring Planka to foreground
wait $PLANKA_PID
