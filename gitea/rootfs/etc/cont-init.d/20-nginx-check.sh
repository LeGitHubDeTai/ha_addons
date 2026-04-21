#!/usr/bin/with-contenv bashio
# Debug script to check nginx setup

set -e

echo "[DEBUG] ==========================================="
echo "[DEBUG] Nginx check script running"
echo "[DEBUG] ==========================================="

# Check if nginx binary exists
echo "[DEBUG] Checking nginx binary..."
which nginx || echo "[DEBUG] nginx not found in PATH"
nginx -v 2>&1 || echo "[DEBUG] nginx -v failed"

# Check nginx config
echo "[DEBUG] Checking nginx config file..."
if [ -f /etc/nginx/nginx.conf ]; then
    echo "[DEBUG] /etc/nginx/nginx.conf exists"
    ls -la /etc/nginx/nginx.conf
else
    echo "[DEBUG] /etc/nginx/nginx.conf NOT FOUND!"
fi

# Check services.d structure
echo "[DEBUG] Checking services.d structure..."
ls -la /etc/services.d/ || echo "[DEBUG] /etc/services.d/ not found"

if [ -d /etc/services.d/nginx ]; then
    echo "[DEBUG] /etc/services.d/nginx directory exists"
    ls -la /etc/services.d/nginx/
    
    if [ -f /etc/services.d/nginx/run ]; then
        echo "[DEBUG] run script exists and is executable:"
        ls -la /etc/services.d/nginx/run
    else
        echo "[DEBUG] run script NOT FOUND!"
    fi
else
    echo "[DEBUG] /etc/services.d/nginx directory NOT FOUND!"
fi

# Test nginx config (don't fail if it fails, let the service handle it)
echo "[DEBUG] Testing nginx configuration..."
nginx -t 2>&1 || echo "[DEBUG] nginx -t failed (will be checked again by service)"

echo "[DEBUG] ==========================================="
echo "[DEBUG] Nginx check complete"
echo "[DEBUG] ==========================================="
