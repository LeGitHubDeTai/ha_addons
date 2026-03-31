#!/usr/bin/with-contenv bashio

# Lire l'option ws_force depuis Home Assistant
WS_FORCE=$(jq -r '.ws_force // "auto"' /data/options.json)

# Créer les dossiers et fixer les permissions
mkdir -p /share/isoman/isos /share/isoman/db
chown -R isoman:isoman /share/isoman

# Exporter la variable pour le frontend via NGINX
export WS_FORCE

# Lancer Isoman
exec /entrypoint.sh ./server