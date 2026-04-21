#!/usr/bin/with-contenv bashio
# Start nginx for ingress in background and keep it running

set -e

bashio::log.info "Starting Nginx for ingress on port 8099..."
mkdir -p /var/log/nginx /var/cache/nginx

# Function to start nginx
start_nginx() {
    while true; do
        bashio::log.info "Starting Nginx..."
        nginx -g 'daemon off;' 2>&1 || true
        bashio::log.warning "Nginx exited, restarting in 5 seconds..."
        sleep 5
    done
}

# Start nginx in background
start_nginx &

# Wait a moment and check
sleep 2
if pgrep -x nginx > /dev/null; then
    bashio::log.info "Nginx is running on port 8099"
else
    bashio::log.error "Nginx failed to start!"
fi

# Keep script running to maintain S6 service tracking
wait
