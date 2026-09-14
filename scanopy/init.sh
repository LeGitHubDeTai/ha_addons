#!/bin/bash
# Scanopy initialization script for daemon API key setup

echo "Starting Scanopy initialization..."

# Wait for server to be ready
echo "Waiting for server to start..."
sleep 15

# Try to create and activate daemon API key
echo "Setting up daemon API key..."
for i in {1..5}; do
    echo "Attempt $i to create API key..."
    
    # Get existing API keys first
    API_KEYS=$(curl -s http://localhost:60072/api/daemon-api-keys || echo "")
    
    # Check if our key already exists
    if echo "$API_KEYS" | grep -q "homeassistant-daemon"; then
        echo "API key already exists, activating it..."
        KEY_ID=$(echo "$API_KEYS" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        # Activate the key
        curl -X PATCH "http://localhost:60072/api/daemon-api-keys/$KEY_ID" \
          -H "Content-Type: application/json" \
          -d '{"active": true}' && \
          echo "API key activated successfully" && \
          exit 0
    else
        # Create new API key
        response=$(curl -s -X POST http://localhost:60072/api/daemon-api-keys \
          -H "Content-Type: application/json" \
          -d '{"name": "homeassistant-daemon", "network_id": "550e8400-e29b-41d4-a716-446655440000", "active": true}')
        
        if echo "$response" | grep -q '"id"'; then
            echo "API key created and activated successfully"
            exit 0
        fi
    fi
    
    echo "Attempt $i failed, retrying in 10 seconds..."
    sleep 10
done

echo "Failed to setup API key after 5 attempts"
exit 1
