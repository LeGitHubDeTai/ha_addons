#!/bin/bash
# Penpot MCP server (Node). Optional but enabled via PENPOT_FLAGS=enable-mcp.
set -e

# shellcheck disable=SC1091
. /app/penpot-env.sh

export PENPOT_MCP_SERVER_HOST="0.0.0.0"

echo "[mcp] starting..."
cd /opt/penpot/mcp
exec su -s /bin/bash penpot -c 'exec node index.js --multi-user'
