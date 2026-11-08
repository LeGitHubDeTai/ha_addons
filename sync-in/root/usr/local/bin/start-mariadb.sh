#!/bin/bash
# MariaDB en tâche de fond (piloté par supervisord).
set -euo pipefail

# shellcheck source=/dev/null
. /usr/local/lib/syncin-helpers.sh

[ -d "$MARIADB_DATADIR/mysql" ] || die "base MariaDB non initialisée ($MARIADB_DATADIR)"
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

MARIADBD="$(command -v mariadbd || command -v mysqld || true)"
[ -n "$MARIADBD" ] || die "mariadbd introuvable"

log "Démarrage de MariaDB (datadir: $MARIADB_DATADIR)..."
exec "$MARIADBD" \
  --user=mysql \
  --datadir="$MARIADB_DATADIR" \
  --socket="$SOCKET" \
  --pid-file=/run/mysqld/mysqld.pid \
  --bind-address=127.0.0.1 \
  --port=3306 \
  --skip-networking=0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_uca1400_ai_ci \
  --max-allowed-packet=1G \
  --innodb-ft-cache-size=16000000
