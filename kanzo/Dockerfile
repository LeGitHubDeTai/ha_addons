# Kanzo — binaire Linux statique (musl) téléchargé depuis les releases GitHub.
# https://github.com/emanuele-em/kanzo
ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH

FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH
ARG KANZO_VERSION="0.3.0"

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    tar \
    xz \
    tzdata \
  && mkdir -p /usr/local/lib /share /media /backup \
  && curl -fL -sS https://raw.githubusercontent.com/LeGitHubDeTai/ha_addons/main/.scripts/bashio-standalone.sh \
      -o /usr/local/lib/bashio-standalone.sh \
  && chmod 644 /usr/local/lib/bashio-standalone.sh

# --- binaire upstream multi-arch (x86_64 / aarch64 musl) ---
RUN set -eux; \
    case "${BUILD_ARCH}" in \
        "amd64") KANZO_TARGET="x86_64-unknown-linux-musl" ;; \
        "aarch64") KANZO_TARGET="aarch64-unknown-linux-musl" ;; \
        *) echo "Unsupported architecture: ${BUILD_ARCH}"; exit 1 ;; \
    esac; \
    curl -fL -sS "https://github.com/emanuele-em/kanzo/releases/download/v${KANZO_VERSION}/kanzo-${KANZO_TARGET}.tar.xz" \
        -o /tmp/kanzo.tar.xz; \
    tar -xJf /tmp/kanzo.tar.xz -C /tmp; \
    install -m 755 "/tmp/kanzo-${KANZO_TARGET}/kanzo" /usr/local/bin/kanzo; \
    rm -rf /tmp/kanzo.tar.xz "/tmp/kanzo-${KANZO_TARGET}"; \
    kanzo --version

# --- scripts ---
COPY root /
RUN chmod +x /usr/local/bin/kanzo-entrypoint.sh

EXPOSE 4242

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:4242/ || exit 1

ENTRYPOINT ["/usr/local/bin/kanzo-entrypoint.sh"]
