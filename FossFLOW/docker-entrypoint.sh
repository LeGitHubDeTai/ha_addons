#!/bin/bash

# FossFLOW Home Assistant Add-on Entrypoint

# Set default port if not specified
export PORT=${PORT:-4000}

# Create data directory if it doesn't exist
mkdir -p /data/diagrams

# Set permissions
chown -R app:app /data 2>/dev/null || chown -R root:root /data

# Start FossFLOW server
echo "Starting FossFLOW server on port $PORT"
echo "Storage path: $STORAGE_PATH"
echo "Server storage enabled: $ENABLE_SERVER_STORAGE"
echo "Git backup enabled: $ENABLE_GIT_BACKUP"

# Start the application - try different possible commands
if command -v fossflow-placeholder &> /dev/null; then
    exec fossflow-placeholder --port $PORT --host 0.0.0.0
elif command -v node &> /dev/null && [ -f "/tmp/fossflow/server.js" ]; then
    exec node /tmp/fossflow/server.js
else
    echo "Starting simple Node.js server for FossFLOW placeholder..."
    exec node -e "
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end(\`
    <h1>FossFLOW Server</h1>
    <p>Placeholder installation</p>
    <p>Port: $PORT</p>
    <p>Storage: $STORAGE_PATH</p>
    <p>This is a temporary placeholder until the actual FossFLOW is installed.</p>
  \`);
});
server.listen($PORT, '0.0.0.0', () => {
  console.log('FossFLOW placeholder server running on port $PORT');
});
"
fi
