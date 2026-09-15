#!/bin/bash
. /app/n8n-exports.sh

echo "N8N_PATH: ${N8N_PATH}"
echo "N8N_EDITOR_BASE_URL: ${N8N_EDITOR_BASE_URL}"
echo "WEBHOOK_URL: ${WEBHOOK_URL}"

###########
## MAIN  ##
###########

# Start localtunnel for OAuth if not already running
if [ -z "${N8N_LT_DISABLE}" ]; then
    if ! pg -x "lt" > /dev/null 2>&1; then
        echo "Starting localtunnel..."
        lt --port 5678 --subdomain n8n-${HOSTNAME} --url "${N8N_EDITOR_BASE_URL}" &
        LT_PID=$!
        echo "Localtunnel PID: ${LT_PID}"
        echo "LT_URL: ${N8N_EDITOR_BASE_URL}"
        
        # Wait for localtunnel to assign a URL
        sleep 3
        
        # Export the tunnel URL
        if [ -n "${N8N_EDITOR_BASE_URL}" ]; then
            export WEBHOOK_URL="${N8N_EDITOR_BASE_URL}"
            echo "Updated WEBHOOK_URL: ${WEBHOOK_URL}"
        fi
    else
        echo "Localtunnel already running"
    fi
else
    echo "Localtunnel disabled via N8N_LT_DISABLE"
fi

if [ "$#" -gt 0 ]; then
  # Got started with arguments
  exec n8n "${N8N_CMD_LINE}"
else
  # Got started without arguments
  exec n8n
fi