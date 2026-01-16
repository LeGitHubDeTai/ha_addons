#!/bin/bash
set -e

# Vérifier que la base de données est joignable (optionnel)
if [ -n "$DOLIBARR_DB_HOST" ]; then
  until mariadb -h "$DOLIBARR_DB_HOST" -u "$DOLIBARR_DB_USER" -p"$DOLIBARR_DB_PASSWORD" "$DOLIBARR_DB_NAME"; do
    echo "Waiting for database..."
    sleep 5
  done
fi

# Lancer Apache en mode foreground
apache2-foreground
