#!/bin/sh

# Lire l'option ws_force depuis Home Assistant
WS_FORCE=$(jq -r '.ws_force // "auto"' /data/options.json)

# Couleurs ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # reset color

# Message coloré
echo -e "${GREEN}[INFO]${NC} WS_FORCE parameter used: ${YELLOW}${WS_FORCE}${NC}"

# Créer les dossiers et fixer les permissions
mkdir -p /share/isoman/isos /share/isoman/db
chown -R isoman:isoman /share/isoman

# Exporter la variable pour le frontend via NGINX
export WS_FORCE

# Lancer Isoman
exec /entrypoint.sh ./server