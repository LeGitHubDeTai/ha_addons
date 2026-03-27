#!/bin/bash
# Fix permissions
chmod 755 /app

# Start nginx in background
nginx -g "daemon off;" &

# Start Node.js app in background  
cd /app && npm start &

# Keep container running
wait
