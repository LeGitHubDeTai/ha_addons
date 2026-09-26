# NZBGet — bas� sur l'image officielle LinuxServer.io
# https://docs.linuxserver.io/images/docker-nzbget/
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="NZBGet" \
  org.opencontainers.image.description="Client de t�l�chargement Usenet (NZBGet) pour Home Assistant" \
  org.opencontainers.image.source="https://github.com/LeGitHubDeTai/ha_addons/tree/main/nzbget" \
  org.opencontainers.image.licenses="GPL-2.0-or-later"

USER root

# Outils n�cessaires : bash + jq pour lire les options HA (bashio),
# tzdata pour la gestion du fuseau horaire.
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    jq \
    tzdata \
  && mkdir -p /usr/local/lib /share /media /backup \
  && curl -fL -sS https://raw.githubusercontent.com/LeGitHubDeTai/ha_addons/main/.scripts/bashio-standalone.sh \
      -o /usr/local/lib/bashio-standalone.sh \
  && chmod 644 /usr/local/lib/bashio-standalone.sh \
  && if [ ! -e /usr/bin/with-contenv ] && [ -e /command/with-contenv ]; then \
       ln -s /command/with-contenv /usr/bin/with-contenv; \
     fi

# Scripts d'initialisation HA (options -> variables d'environnement LinuxServer)
COPY root/ /

RUN chmod +x /etc/cont-init.d/10-nzbget-ha.sh

EXPOSE 6789 6790
