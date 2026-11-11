# Kanzo — compilé depuis les sources (crates.io), en multi-étapes.
#
# Pourquoi pas le binaire précompilé upstream ? Les releases x86_64
# contiennent des instructions BMI2 (sarx/shlx/shrx) qui provoquent un
# SIGILL au démarrage sur les CPU sans BMI2 (avant Haswell, anciennes VM) :
# kanzo meurt silencieusement avant même d'imprimer "Kanzo board at ...".
# La compilation locale avec l'outilchain Alpine produit un binaire à
# l'ISA de base (x86-64 / armv8), compatible avec tous les CPU supportés.
#
# https://github.com/emanuele-em/kanzo
ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH

# --- Étape 1 : compilation du binaire ---
FROM rust:1-alpine AS kanzo-builder
ARG KANZO_VERSION="0.4.2"
# build-base = gcc, musl-dev, make (requis pour rusqlite/sqlite3.c)
RUN apk add --no-cache build-base ca-certificates \
  && cargo install kanzo --version "${KANZO_VERSION}" --locked

# --- Étape 2 : image finale ---
#
# Architecture : nginx (4243, Ingress HA + accès réseau direct) -> Kanzo sur
# 127.0.0.1:4242. nginx réécrit Host/Origin et les URLs absolues de Kanzo,
# qui n'est pas compatible avec l'Ingress de son état (voir nginx.conf).
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Outils : bash + jq pour les options HA (bashio), curl pour le healthcheck,
# nginx (reverse proxy Ingress), supervisor (gestion des processus).
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    nginx \
    supervisor \
    tzdata \
  && mkdir -p /usr/local/lib /share /media /backup \
  && curl -fL -sS https://raw.githubusercontent.com/LeGitHubDeTai/ha_addons/main/.scripts/bashio-standalone.sh \
      -o /usr/local/lib/bashio-standalone.sh \
  && chmod 644 /usr/local/lib/bashio-standalone.sh

# --- binaire compilé à l'étape précédente ---
COPY --from=kanzo-builder /usr/local/cargo/bin/kanzo /usr/local/bin/kanzo

# --- reverse proxy + supervision ---
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

# --- scripts ---
COPY root /
RUN chmod +x /usr/local/bin/kanzo-entrypoint.sh

EXPOSE 4243

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:4243/ || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
