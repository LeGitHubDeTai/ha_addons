#!/bin/bash
# Fonctions partagées par les scripts de l'add-on Sync-in.
# Ce fichier est sourcé (il ne contient aucune commande d'exécution).

log() { echo "[sync-in] $*"; }
die() { echo "[sync-in] ERREUR: $*" >&2; exit 1; }

# Chemins partagés (surchargables par l'environnement)
: "${SECRETS_FILE:=/data/.secrets}"
: "${SOCKET:=/run/mysqld/mysqld.sock}"
: "${MARIADB_DATADIR:=/data/mariadb}"
: "${DB_NAME:=sync_in}"

# Binaire client MariaDB (mariadb, ou mysql selon la distribution)
mysql_bin() {
  if command -v mariadb >/dev/null 2>&1; then
    command -v mariadb
  elif command -v mysql >/dev/null 2>&1; then
    command -v mysql
  else
    return 1
  fi
}

# 32 octets en hexadécimale (secret aléatoire)
rand_secret() {
  od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
}

# Lit une valeur persistée dans $SECRETS_FILE (cut = pas d'interprétation
# de & ou \ dans la valeur, contrairement au remplacement sed).
# `|| true` est indispensable : sans fichier ou sans clé, grep renvoie 1 et
# set -euo pipefail tuerait le script silencieusement (aucun log).
stored_secret() {
  grep "^$1=" "$SECRETS_FILE" 2>/dev/null | tail -n 1 | cut -d= -f2- || true
}

# Écrit/Remplace une valeur persistée dans $SECRETS_FILE
save_secret() {
  mkdir -p "$(dirname "$SECRETS_FILE")"
  touch "$SECRETS_FILE"
  grep -v "^$1=" "$SECRETS_FILE" > "${SECRETS_FILE}.tmp" 2>/dev/null || true
  mv "${SECRETS_FILE}.tmp" "$SECRETS_FILE"
  printf '%s=%s\n' "$1" "$2" >> "$SECRETS_FILE"
  chmod 600 "$SECRETS_FILE"
}

# Résout un secret : valeur de l'option si définie, sinon valeur générée
# mémorisée (les secrets restent stables d'un redémarrage à l'autre).
resolve_secret() {
  local opt_val="$1" key="$2" stored
  stored="$(stored_secret "$key")"
  if [ -n "$opt_val" ]; then
    if [ "$opt_val" != "$stored" ]; then
      save_secret "$key" "$opt_val"
    fi
    printf '%s' "$opt_val"
  else
    if [ -z "$stored" ]; then
      stored="$(rand_secret)"
      save_secret "$key" "$stored"
    fi
    printf '%s' "$stored"
  fi
}

# Échappement pour un littéral YAML entre guillemets simples
yaml_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

# Échappement pour un littéral SQL entre guillemets simples
sql_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/''/g"
}
