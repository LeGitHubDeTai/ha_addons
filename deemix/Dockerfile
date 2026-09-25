# Deemix — Téléchargeur de musique Deezer (interface web)
# Upstream : https://github.com/bambanah/deemix (fork maintenu du projet de RemixDev)
# Stratégie : on réutilise l'application précompilée (/app) de l'image officielle
# multi-arch (amd64 + arm64) et on l'exécute avec Node.js 24 sur la base HA.
ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH

# Version de l'app upstream (packages/webui/package.json). Mise à jour par le workflow auto-upgrade-deemix.
ARG DEEMIX_VERSION=4.7.0

# Application précompilée (turbo build) depuis l'image officielle
FROM ghcr.io/bambanah/deemix:v${DEEMIX_VERSION} AS upstream

# Node.js 24 LTS (multi-arch) — deemix exige Node >= 24
FROM node:24-alpine AS node_upstream

# ===============================
# RUNTIME : base Home Assistant
# ===============================
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_CONFIG_FILE
ARG DEEMIX_VERSION

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="Deemix" \
  org.opencontainers.image.description="Téléchargeur de musique Deezer avec interface web (Deemix)" \
  org.opencontainers.image.source="https://github.com/LeGitHubDeTai/ha_addons/tree/main/deemix" \
  org.opencontainers.image.url="https://github.com/bambanah/deemix" \
  org.opencontainers.image.version="${DEEMIX_VERSION}"

ENV NODE_ENV=production

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    libgcc \
    libstdc++ \
    nginx \
    supervisor \
    tzdata

# Node.js 24 depuis l'image officielle (même arch que le build en cours)
COPY --from=node_upstream /usr/local/bin/node /usr/local/bin/node
RUN node --version

# Application Deemix précompilée depuis l'image upstream (même arch).
# Le serveur démarre avec : node /app/packages/webui/dist/main.js
# La CLI est aussi disponible : node /app/packages/cli/dist/main.cjs
COPY --from=upstream /app /app

# Patch Ingress HA : le client construit des URLs absolues depuis
# location.origin/host (hors préfixe /api/hassio_ingress/<token>/) et le CSS
# utilise des url(/fonts/...) absolus. Le script échoue si l'upstream change.
COPY patch-frontend.py /tmp/patch-frontend.py
RUN python3 /tmp/patch-frontend.py /app/packages/webui/dist/public \
    && rm /tmp/patch-frontend.py

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY deemix-entrypoint.sh /app/deemix-entrypoint.sh
RUN chmod +x /app/deemix-entrypoint.sh \
    && mkdir -p /run/nginx /var/log/supervisor

EXPOSE 6595

# L'app écoute en interne sur 6596 (nginx expose 6595 : direct + ingress)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:6596/ || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
