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

# Create full Nginx configuration based on isoman pattern
mkdir -p /etc/nginx

cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen ${INGRESS_PORT};

        location / {
            proxy_pass http://127.0.0.1:${GITEA_PORT};

            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Origin \$scheme://\$host;
            proxy_cache off;
            proxy_buffering off;

            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # Allow large file uploads
            client_max_body_size 0;
            proxy_connect_timeout 600;
            proxy_send_timeout 600;
            proxy_read_timeout 600;

            # Ingress fix for URL rewriting
            set \$ingress_path \$http_x_ingress_path;

            sub_filter_types text/html text/css application/javascript;
            sub_filter_once off;
            sub_filter 'href="/'  'href="\$ingress_path/';
            sub_filter 'src="/'   'src="\$ingress_path/';
            sub_filter 'action="/' 'action="\$ingress_path/';
        }
    }
}
EOF

# Test nginx configuration
if ! nginx -t 2>&1; then
    bashio::log.error "Nginx configuration test failed"
    exit 1
fi

bashio::log.info "Nginx ingress configured on port ${INGRESS_PORT}"
