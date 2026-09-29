#!/bin/bash
# shellcheck shell=bash
#
# 10-lidarr-ha.sh — applique les options de l'add-on Home Assistant.
#
# Exécuté par le service init-custom-files de LinuxServer
# (/custom-cont-init.d), AVANT le démarrage des services (init-services).
# Note : ce script tourne via "/bin/bash script" (pas de with-contenv) ;
# les `export` ne se propageraient donc pas aux services s6. Les valeurs
# sont injectées directement là où elles sont consommées (voir ci-dessous).
set -e

# Charge bashio (fallback standalone embarqué dans l'image)
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

bashio::log.info "Options HA : PUID=${PUID} PGID=${PGID} TZ=${HA_TZ}"

# PUID/PGID : init-adduser de LinuxServer lit l'environnement ($PUID, défaut
# 911). On y injecte les valeurs des options en tête de script, juste après
# le shebang : prioritaire sur l'environnement, robuste aux évolutions
# internes (pas de motif fragile, simple insertion ligne 2/3).
if [ -f /etc/s6-overlay/s6-rc.d/init-adduser/run ]; then
  sed -i "1a PGID=\"${PGID}\"" /etc/s6-overlay/s6-rc.d/init-adduser/run
  sed -i "1a PUID=\"${PUID}\"" /etc/s6-overlay/s6-rc.d/init-adduser/run
  bashio::log.info "PUID/PGID injectés dans init-adduser"
else
  bashio::log.warning "init-adduser introuvable, PUID/PGID non appliqués"
fi

# TZ : applique le fuseau horaire au niveau système (utilisé par Lidarr),
# en complément de la variable d'environnement TZ.
if [ -f "/usr/share/zoneinfo/${HA_TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${HA_TZ}" /etc/localtime
  echo "${HA_TZ}" > /etc/timezone
  bashio::log.info "Fuseau horaire : ${HA_TZ}"
else
  bashio::log.warning "Fuseau horaire inconnu : ${HA_TZ}, ignoré"
fi

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
