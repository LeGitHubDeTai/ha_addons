#!/bin/bash
set -e

# Generate nginx configuration based on environment variables
cat > /etc/nginx/conf.d/default.conf << EOF
server {
    listen 60072;
    server_name localhost;
    
    # Proxy to Scanopy server
    location / {
        proxy_pass http://localhost:60072;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo "Nginx configuration generated. Starting nginx..."
