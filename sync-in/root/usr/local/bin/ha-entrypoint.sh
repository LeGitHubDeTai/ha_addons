#!/bin/bash
# Point d'entrée principal de l'add-on Sync-in (PID 1).
#
# 1. Lit les options Home Assistant (/data/options.json)
# 2. Prépare l'utilisateur MariaDB, les secrets et le dossier de données
# 3. Génère /app/environment/environment.yaml (configuration de Sync-in)
# 4. Lance supervisord (MariaDB + serveur Sync-in)
set -euo pipefail

# shellcheck source=/dev/null
. /usr/local/lib/syncin-helpers.sh

OPTIONS_FILE=/data/options.json
ENVIRONMENT_FILE=/app/environment/environment.yaml
DEFAULT_DATA_DIR=/share/sync-in

[ -f "$OPTIONS_FILE" ] || die "options Home Assistant introuvables: $OPTIONS_FILE"
command -v jq >/dev/null 2>&1 || die "jq est requis"

opt() { jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS_FILE"; }

# --- Options --------------------------------------------------------------
TZ_NAME="$(opt TZ)"
[ -n "$TZ_NAME" ] || TZ_NAME="Europe/Paris"
export TZ="$TZ_NAME"

DATA_DIR="$(opt data_dir)"
[ -n "$DATA_DIR" ] || DATA_DIR="$DEFAULT_DATA_DIR"
case "$DATA_DIR" in
  /share/*|/media/*) ;;
  *) die "data_dir doit commencer par /share/ ou /media/ (reçu: $DATA_DIR)" ;;
esac

PUBLIC_URL="$(opt public_url)"
INIT_ADMIN_LOGIN="$(opt init_admin_login)"
INIT_ADMIN_PASSWORD="$(opt init_admin_password)"

PUID="${PUID:-8888}"
PGID="${PGID:-8888}"
export PUID PGID

# Le compte administrateur est créé au premier démarrage
# (voir scripts/docker-sync-in-server.sh de l'image upstream)
export INIT_ADMIN=true
if [ -n "$INIT_ADMIN_LOGIN" ]; then export INIT_ADMIN_LOGIN; fi
if [ -n "$INIT_ADMIN_PASSWORD" ]; then export INIT_ADMIN_PASSWORD; fi

# --- Fuseau horaire -------------------------------------------------------
if [ -f "/usr/share/zoneinfo/$TZ_NAME" ]; then
  ln -snf "/usr/share/zoneinfo/$TZ_NAME" /etc/localtime
  echo "$TZ_NAME" > /etc/timezone
else
  log "Fuseau horaire inconnu: $TZ_NAME"
fi

# --- Utilisateur MariaDB (paquet Alpine `mariadb`) ------------------------
if ! getent group mysql >/dev/null 2>&1; then
  addgroup -g 84 mysql 2>/dev/null || addgroup mysql
fi
if ! getent passwd mysql >/dev/null 2>&1; then
  adduser -D -G mysql mysql
fi

# --- Secrets --------------------------------------------------------------
mkdir -p /data
export SECRETS_FILE
DB_PASSWORD="$(resolve_secret "$(opt db_root_password)" db_root_password)"
ENCRYPTION_KEY="$(resolve_secret "$(opt encryption_key)" encryption_key)"
ACCESS_SECRET="$(resolve_secret "$(opt access_secret)" access_secret)"
REFRESH_SECRET="$(resolve_secret "$(opt refresh_secret)" refresh_secret)"
DB_PASSWORD_APPLIED="$(stored_secret db_password_applied)"
export DB_PASSWORD DB_PASSWORD_APPLIED

# --- Variables d'environnement supplémentaires (env_vars_list) ------------
while IFS= read -r kv; do
  [ -n "$kv" ] || continue
  key="${kv%%:*}"
  value="${kv#*:}"
  value="${value# }"
  case "$key" in
    ''|*[!A-Za-z0-9_]*) log "Variable ignorée (nom invalide): '$key'" ;;
    *) export "${key}=${value}" ;;
  esac
done < <(jq -r '(.env_vars_list // [])[]?' "$OPTIONS_FILE")

# --- MariaDB : répertoires et initialisation ------------------------------
mkdir -p "$MARIADB_DATADIR" /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "$MARIADB_DATADIR/mysql" ]; then
  INSTALL_DB="$(command -v mariadb-install-db || command -v mysql_install_db || true)"
  [ -n "$INSTALL_DB" ] || die "mariadb-install-db introuvable"
  log "Initialisation de la base MariaDB (premier démarrage)..."
  chown -R mysql:mysql "$MARIADB_DATADIR"
  "$INSTALL_DB" --user=mysql --datadir="$MARIADB_DATADIR" --skip-test-db \
    || die "échec de mariadb-install-db"
fi

# --- Données Sync-in ------------------------------------------------------
# Sync-in impose le chemin interne /app/data : on remplace le dossier vide de
# l'image par un lien symbolique vers le dossier choisi dans les options.
mkdir -p "$DATA_DIR"
if [ -L /app/data ] || [ -d /app/data ]; then
  rm -rf /app/data   # dossier de l'image, vide au premier démarrage
fi
ln -s "$DATA_DIR" /app/data
if [ "$(stat -c '%u:%g' "$DATA_DIR")" != "$PUID:$PGID" ]; then
  chown -R "$PUID:$PGID" "$DATA_DIR"
fi
# Le lien lui-même porte PUID/PGID : l'entrypoint officiel ne déclenche alors
# pas de chown -R inutile à chaque démarrage.
chown -h "$PUID:$PGID" /app/data 2>/dev/null || true

# --- Configuration Sync-in -------------------------------------------------
mkdir -p /app/environment
{
  if [ -n "$PUBLIC_URL" ]; then
    printf "server:\n  publicUrl: '%s'\n" "$(yaml_escape "$PUBLIC_URL")"
  fi
  printf "mysql:\n  url: 'mysql://root:%s@127.0.0.1:3306/%s'\n" \
    "$(yaml_escape "$DB_PASSWORD")" "$DB_NAME"
  printf "auth:\n  encryptionKey: '%s'\n  token:\n    access:\n      secret: '%s'\n    refresh:\n      secret: '%s'\n" \
    "$(yaml_escape "$ENCRYPTION_KEY")" \
    "$(yaml_escape "$ACCESS_SECRET")" \
    "$(yaml_escape "$REFRESH_SECRET")"
} > "$ENVIRONMENT_FILE"
chown "$PUID:$PGID" "$ENVIRONMENT_FILE"
chmod 600 "$ENVIRONMENT_FILE"
log "Configuration écrite: $ENVIRONMENT_FILE"

# --- Démarrage ------------------------------------------------------------
log "Démarrage de supervisord (MariaDB + Sync-in)..."
exec supervisord -c /etc/supervisord.conf
