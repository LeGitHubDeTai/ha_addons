#!/bin/bash
. /app/n8n-exports.sh

# Copy n8n config file if it doesn't exist
if [ ! -f "/data/n8n/n8n-config.json" ]; then
    mkdir -p /data/n8n
    cp /app/n8n-config.json /data/n8n/n8n-config.json
fi

echo "N8N_PATH: ${N8N_PATH}"
echo "N8N_EDITOR_BASE_URL: ${N8N_EDITOR_BASE_URL}"
echo "WEBHOOK_URL: ${WEBHOOK_URL}"

###########
## MAIN  ##
###########

if [ "$#" -gt 0 ]; then
  # Got started with arguments
  exec n8n "${N8N_CMD_LINE}"
else
  # Got started without arguments
  exec n8n
fi
