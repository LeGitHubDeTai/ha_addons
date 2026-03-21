#!/bin/bash

# Simple startup script for Scanopy addon

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
    killall scanopy-daemon 2>/dev/null || true
    nginx -s quit 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Read configuration from Home Assistant environment variables
LOG_LEVEL="${log_level:-info}"
DATABASE_URL="${database_url:-}"
PUBLIC_URL="${public_url:-http://localhost:60072}"
ENABLE_DOCKER_DISCOVERY="${enable_docker_discovery:-true}"
INITIAL_INTERVAL="${scan_intervals_initial:-5m}"
RECURRING_INTERVAL="${scan_intervals_recurring:-1h}"

# Set required environment variables for daemon
export SCANOPY_DAEMON_URL="http://localhost:60073"
export SCANOPY_SERVER_URL="http://localhost:60072"
export SCANOPY_PUBLIC_URL="$PUBLIC_URL"
export SCANOPY_LOG_LEVEL="$LOG_LEVEL"
export DATABASE_URL="$DATABASE_URL"
export SCANOPY_ENABLE_DOCKER_DISCOVERY="$ENABLE_DOCKER_DISCOVERY"
export SCANOPY_INITIAL_INTERVAL="$INITIAL_INTERVAL"
export SCANOPY_RECURRING_INTERVAL="$RECURRING_INTERVAL"

# Start daemon and check which port it uses
echo "Starting daemon..."
echo "Log level: $LOG_LEVEL"
echo "Database URL: ${DATABASE_URL:0:20}..." # Show only first 20 chars for security
echo "Public URL: $PUBLIC_URL"
echo "Docker discovery: $ENABLE_DOCKER_DISCOVERY"
echo "Checking available ports before daemon starts..."
netstat -tlnp | grep -E ":(6007[0-9]|8080|3000|5173)" || echo "No conflicting ports found"
/opt/scanopy-daemon &
sleep 5  # Give daemon more time to start
echo "Checking ports after daemon starts..."
netstat -tlnp | grep -E ":(6007[0-9]|8080|3000|5173)" || echo "Daemon port not found in listening state"

# Start a simple server to handle /api/initialize
echo "Starting initialization server on port 60075..."
python3 -c "
import http.server
import socketserver
import json
import threading
import time
import requests

class InitHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/initialize':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            print(f'Initialize request: {post_data}')
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {'network_id': 'scanopy-network-1', 'status': 'initialized'}
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/api/work':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            print(f'Work request: {post_data}')
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {'status': 'no_work', 'message': 'No work available'}
            self.wfile.write(json.dumps(response).encode())
        else:
            super().do_POST()

# Auto-initialize the daemon after 5 seconds
def auto_initialize():
    time.sleep(5)
    try:
        print('Auto-initializing daemon...')
        response = requests.post('http://localhost:60073/api/initialize', 
                               json={'network_id': 'scanopy-network-1'}, 
                               timeout=5)
        print(f'Initialize response: {response.text}')
    except Exception as e:
        print(f'Auto-initialize failed: {e}')

# Start auto-initialize in background
threading.Thread(target=auto_initialize, daemon=True).start()

with socketserver.TCPServer(('', 60075), InitHandler) as httpd:
    print('Init server running on port 60075')
    httpd.serve_forever()
" &

# Start nginx on port 60072 (external access)
echo "Starting nginx on port 60072..."
# Copy our custom index.html to UI directory
cp /index.html /opt/scanopy-ui/
nginx -g "daemon off;" &

# Wait for processes
wait
