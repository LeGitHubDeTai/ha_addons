# Requestly — Open-Source HTTP Interceptor & API Mocks
# Source : https://github.com/requestly/interceptor (branche master, app/ = web UI Vite)
# Build : compilation du front (app/build) puis servi en statique via nginx (comme storybook).
ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH

# Version informative de l'app upstream (app/package.json). Mise à jour par le workflow auto-upgrade-requestly.
ARG REQUESTLY_APP_VERSION=26.8.14
ARG REQUESTLY_REF=master

# ===============================
# BUILDER : compile la web UI
# ===============================
FROM node:20-bookworm AS builder

ARG REQUESTLY_REF
ARG REQUESTLY_APP_VERSION

ENV CI=false
ENV GENERATE_SOURCEMAP=false
ENV NODE_OPTIONS=--max-old-space-size=4096

RUN apt-get update \
    && apt-get install -y --no-install-recommends git python3 make g++ \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /src

# Clone peu profond de la branche suivie (défaut: master)
RUN git clone --depth 1 --branch ${REQUESTLY_REF} https://github.com/requestly/interceptor.git .

# Installation complète (root core + shared + app + rule-processor + analytics-vendors + extension).
# L'extension navigateur n'est pas servie par l'add-on, mais install.sh l'installe — on l'accepte pour rester fidèle à l'upstream.
RUN sh ./install.sh

# Build des modules requis par app/ (sans l'extension navigateur pour gagner du temps)
RUN cd common/analytics-vendors && sh build.sh && cd ../..
RUN cd common/rule-processor && sh build.sh && cd ../..
RUN npm run build
RUN cd shared && npm run build && cd ..

# Build de la web app (vite build -> app/build/)
RUN cd app && npm run build && ls -la build | head -20

# ===============================
# RUNTIME : HA base + nginx statique
# ===============================
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_CONFIG_FILE
ARG REQUESTLY_APP_VERSION
ARG REQUESTLY_REF

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="Requestly" \
  org.opencontainers.image.description="Intercepteur HTTP, mocks d'API et débogage réseau (Requestly)" \
  org.opencontainers.image.source="https://github.com/LeGitHubDeTai/ha_addons/tree/main/requestly" \
  org.opencontainers.image.url="https://requestly.com/" \
  org.opencontainers.image.version="${REQUESTLY_APP_VERSION}"

RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    ca-certificates \
    tzdata

RUN mkdir -p /usr/share/nginx/html /var/log/supervisor /run/nginx

# Web UI compilée
COPY --from=builder /src/app/build/ /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 3000

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
