#!/bin/bash
# Attend que MariaDB soit prêt, synchronise les accès (mot de passe root,
# base de données), puis lance le serveur Sync-in (image upstream).
set -euo pipefail

# shellcheck source=/dev/null
. /usr/local/lib/syncin-helpers.sh

DB_USER=root
: "${DB_PASSWORD:?DB_PASSWORD doit être défini par ha-entrypoint.sh}"
DB_PASSWORD_APPLIED="${DB_PASSWORD_APPLIED:-}"

MYSQL="$(mysql_bin)" || die "client MariaDB introuvable"

# Exécute du SQL sur le socket local.
# $1 = mot de passe (vide = sans mot de passe), $2 = requête SQL
run_sql() {
  local pw="$1" query="$2"
  if [ -n "$pw" ]; then
    "$MYSQL" --protocol=socket --socket="$SOCKET" -u"$DB_USER" -p"$pw" \
      --batch --skip-column-names -e "$query"
  else
    "$MYSQL" --protocol=socket --socket="$SOCKET" -u"$DB_USER" \
      --batch --skip-column-names -e "$query"
  fi
}

try_auth() { run_sql "$1" "SELECT 1" >/dev/null 2>&1; }

# --- Attente de MariaDB ---------------------------------------------------
AUTH_PW=""
AUTH_OK=false
log "Attente de MariaDB..."
for _ in {1..120}; do
  if try_auth "$DB_PASSWORD"; then
    AUTH_PW="$DB_PASSWORD"
    AUTH_OK=true
    break
  fi
  if [ -n "$DB_PASSWORD_APPLIED" ] && [ "$DB_PASSWORD_APPLIED" != "$DB_PASSWORD" ] \
    && try_auth "$DB_PASSWORD_APPLIED"; then
    AUTH_PW="$DB_PASSWORD_APPLIED"
    AUTH_OK=true
    break
  fi
  if try_auth ""; then
    AUTH_PW=""
    AUTH_OK=true
    break
  fi
  sleep 1
done
if [ "$AUTH_OK" != "true" ]; then
  die "MariaDB inaccessible après 120 s (socket: $SOCKET)"
fi

# --- Authentification root : mot de passe + plugin ------------------------
# ALTER systématique (idempotent) : root@localhost est créé par MariaDB comme
# `mysql_native_password USING 'invalid' OR unix_socket`. En socket, le
# fallback unix_socket (OS root) fait "réussir" n'importe quel test de mot
# de passe, ce qui rendait toute condition de test fausse et laissait le
# compte en 'invalid' : la connexion TCP de Sync-in échouait alors en
# ERROR 1698. On impose donc le mot de passe attendu à chaque démarrage.
log "Configuration du mot de passe root MariaDB..."
run_sql "$AUTH_PW" \
  "ALTER USER 'root'@'localhost' IDENTIFIED BY '$(sql_escape "$DB_PASSWORD")'; FLUSH PRIVILEGES;" \
  || die "impossible de définir le mot de passe root MariaDB"

# --- Accès TCP + base de données ------------------------------------------
PW_ESC="$(sql_escape "$DB_PASSWORD")"
run_sql "$DB_PASSWORD" "
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '${PW_ESC}';
ALTER USER 'root'@'127.0.0.1' IDENTIFIED BY '${PW_ESC}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci;
FLUSH PRIVILEGES;
" || die "impossible de configurer la base de données"

save_secret db_password_applied "$DB_PASSWORD"
log "Base '${DB_NAME}' prête."

# --- Serveur Sync-in ------------------------------------------------------
log "Démarrage du serveur Sync-in..."
exec /app/entrypoint.sh /app/sync-in-server.sh
