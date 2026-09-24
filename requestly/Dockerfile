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

# Self-host (HA) : l'upstream redirige tout hostname non allowlisté vers
# https://app.requestly.io (voir le <script> en tête de app/index.html : seuls
# localhost, IP nues et *.requestly.io passent). Derrière HA (ingress,
# homeassistant.local, duckdns...) ça rend l'add-on inutilisable.
# On neutralise donc cette redirection avant compilation. Le build échoue
# volontairement si le motif upstream change, pour le détecter.
RUN python3 <<'EOF'
import pathlib
p = pathlib.Path("app/index.html")
s = p.read_text()
old = 'window.location.href = "https://app.requestly.io";'
assert old in s, "motif de redirection introuvable dans app/index.html (l'upstream a changé ?)"
p.write_text(s.replace(old, "/* self-hosted (HA addon) : redirection cloud desactivee */;"))
print("index.html patche : redirection cloud neutralisee")
EOF

# Build de la web app (vite build -> app/build/)
RUN cd app && npm run build && ls -la build | head -20

# Garde-fou : le HTML servi ne doit plus contenir la redirection cloud
RUN if grep -q 'window.location.href = "https://app.requestly.io"' app/build/index.html; then echo "ERREUR : redirection cloud toujours presente dans le build"; exit 1; fi \
    && echo "OK : pas de redirection cloud dans le build"

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
