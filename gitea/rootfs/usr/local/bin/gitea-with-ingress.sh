#!/usr/bin/with-contenv bashio
# Wrapper to start both nginx and gitea

set -e

bashio::log.info "=== Starting Gitea with Ingress support ==="

# Ensure directories exist
mkdir -p /var/log/nginx /var/cache/nginx /run/nginx

# Function to start nginx in foreground (managed by this script)
start_nginx() {
    bashio::log.info "Starting Nginx on port 8099..."
    exec nginx -g 'daemon off;'
}

# Function to start gitea
cd /app/gitea || cd /data/gitea || true

# Start nginx in background subshell
(
    while true; do
        bashio::log.info "[Nginx] Starting..."
        nginx -g 'daemon off;' 2>&1 || true
        bashio::log.warning "[Nginx] Crashed, restarting in 3s..."
        sleep 3
    done
) &
NGINX_BG_PID=$!

# Wait a moment for nginx to start
sleep 2

# Check if nginx is running
if pgrep -x nginx > /dev/null; then
    bashio::log.info "Nginx is running on port 8099"
else
    bashio::log.warning "Nginx may not have started properly"
fi

# Start Gitea in foreground
bashio::log.info "Starting Gitea..."
exec /usr/bin/entrypoint
