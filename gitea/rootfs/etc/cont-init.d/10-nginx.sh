#!/bin/bash
# Nginx configuration for Home Assistant Ingress
# Configures Nginx to proxy requests to Gitea for Home Assistant ingress

set -e

# Read ingress configuration
if bashio::config.has_value "ingress_port"; then
    INGRESS_PORT=$(bashio::config "ingress_port")
else
    INGRESS_PORT=8099
fi

# Get Gitea internal port (usually 3000)
GITEA_PORT=3000

# Create Nginx configuration
mkdir -p /etc/nginx/conf.d

cat > /etc/nginx/conf.d/ingress.conf << EOF
server {
    listen ${INGRESS_PORT};
    listen [::]:${INGRESS_PORT};

    # Allow large file uploads
    client_max_body_size 0;
    
    # Timeouts
    proxy_connect_timeout 600;
    proxy_send_timeout 600;
    proxy_read_timeout 600;
    send_timeout 600;

    location / {
        # Proxy to Gitea
        proxy_pass http://127.0.0.1:${GITEA_PORT};
        
        # Headers for proxy
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

# Ensure Nginx is configured to load conf.d
if [ -f /etc/nginx/nginx.conf ]; then
    # Check if conf.d is included
    if ! grep -q "conf.d" /etc/nginx/nginx.conf; then
        # Add conf.d include
        sed -i '/http {/a \    include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf || true
    fi
fi

bashio::log.info "Nginx ingress configured on port ${INGRESS_PORT}"
