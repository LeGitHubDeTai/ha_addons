#!/usr/bin/with-contenv bash
# shellcheck shell=bash
#
# 10-lidarr-ha.sh — applique les options de l'add-on Home Assistant
# aux variables d'environnement LinuxServer (PUID / PGID / TZ).
#
# Exécuté par s6-overlay AVANT les scripts d'init LinuxServer
# (init-adduser, init-config, ...). Grâce à `with-contenv`, les
# variables exportées ici sont propagées aux services suivants.
set -e

# Charge bashio (version embarquée dans l'image HA ou fallback standalone)
if ! command -v bashio::config >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  for _bashio in /usr/lib/bashio/bashio.sh /usr/local/lib/bashio-standalone.sh; do
    if [ -f "$_bashio" ]; then
      . "$_bashio"
      break
    fi
  done
fi

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"
HA_TZ="$(bashio::config 'TZ')"

export PUID PGID
export TZ="$HA_TZ"

bashio::log.info "Options HA : PUID=${PUID} PGID=${PGID} TZ=${HA_TZ}"

# Lidarr n'utilise pas cron : désactive le service svc-cron de LinuxServer.
# Sans cela, busybox crond tourne en niveau verbeux (-l 5) et inonde le journal
# ("file root:", "line run-parts /etc/periodic/...", "wakeup dt=60", ...).
# Sans risque : svc-lidarr ne dépend que de init-services.
if [ -d /etc/s6-overlay/s6-rc.d/svc-cron ]; then
  touch /etc/s6-overlay/s6-rc.d/svc-cron/down
  bashio::log.info "Service cron désactivé (inutile pour Lidarr)"
else
  bashio::log.info "Aucun service svc-cron détecté, rien à désactiver"
fi

# Dossiers pratiques créés au premier démarrage (ignorés s'ils existent déjà)
for _dir in /share/music /share/downloads; do
  if [ ! -d "$_dir" ]; then
    mkdir -p "$_dir" || bashio::log.warning "Impossible de créer ${_dir}"
  fi
done

# Ajuste le propriétaire des dossiers créés par l'add-on (jamais la racine des montages)
if [ "$PUID" != "0" ] || [ "$PGID" != "0" ]; then
  chown "$PUID:$PGID" /share/music /share/downloads 2>/dev/null \
    || bashio::log.warning "chown ${PUID}:${PGID} impossible sur /share/music et /share/downloads"
fi
