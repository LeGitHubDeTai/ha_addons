# Sync-in — basé sur l'image officielle syncin/server (Alpine + Node.js)
# https://hub.docker.com/r/syncin/server
# L'add-on est mono-conteneur : MariaDB est installé dans l'image.
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="Sync-in" \
    org.opencontainers.image.description="Suite collaborative auto-hébergée (Sync-in) pour Home Assistant" \
    org.opencontainers.image.source="https://github.com/LeGitHubDeTai/ha_addons/tree/main/sync-in"

USER root

# MariaDB (base de données de Sync-in) + outils de lecture des options HA
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    mariadb \
    mariadb-client \
    supervisor \
    tzdata \
  && mkdir -p /run/mysqld /app/static/releases \
  && chown -R 8888:8888 /app/static

# Scripts de démarrage : entrée HA, MariaDB, Sync-in, helpers partagés
COPY root/ /

RUN chmod +x \
    /usr/local/bin/ha-entrypoint.sh \
    /usr/local/bin/start-mariadb.sh \
    /usr/local/bin/start-syncin.sh \
  && chmod 644 /usr/local/lib/syncin-helpers.sh

EXPOSE 8080

# Le HEALTHCHECK de l'image upstream (node .../check-health.js) est conservé.
ENTRYPOINT ["/usr/local/bin/ha-entrypoint.sh"]
