# CTFREAK — basé sur l'image officielle JYP Software
# https://hub.docker.com/r/jypsoftware/ctfreak
# L'image upstream n'est publiée qu'en amd64 (pas de aarch64).
#
# Architecture : nginx (6701, exposé à Ingress) -> CTFREAK (6700, interne).
# nginx patch le JS pour que les URLs API/SSE incluent le préfixe Ingress
# (CTFREAK utilise window.location.origin, qui l'ignore).
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="CTFREAK" \
  org.opencontainers.image.description="Planificateur de tâches IT auto-hébergé (CTFREAK) - ordonnance, exécute et surveille vos scripts et commandes sur vos serveurs" \
  org.opencontainers.image.source="https://github.com/LeGitHubDeTai/ha_addons/tree/main/ctfreak" \
  org.opencontainers.image.licenses="Commercial"

USER root

# Outils : bash + jq pour lire les options HA (bashio), curl pour le healthcheck,
# nginx (reverse proxy Ingress), supervisor (gestion des processus).
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    jq \
    nginx \
    supervisor \
    tzdata \
  && mkdir -p /usr/local/lib /share /media /backup \
  && curl -fL -sS https://raw.githubusercontent.com/LeGitHubDeTai/ha_addons/main/.scripts/bashio-standalone.sh \
      -o /usr/local/lib/bashio-standalone.sh \
  && chmod 644 /usr/local/lib/bashio-standalone.sh

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY root/usr/local/bin/ctfreak-entrypoint.sh /usr/local/bin/ctfreak-entrypoint.sh
RUN chmod +x /usr/local/bin/ctfreak-entrypoint.sh

EXPOSE 6701

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:6701/ | grep -qE '^[2-4][0-9]{2}$' || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
