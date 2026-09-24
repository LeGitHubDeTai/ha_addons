ARG BUILD_FROM=oven/bun:1.3.5-alpine
FROM $BUILD_FROM

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Install build dependencies and system tools
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    nginx \
    supervisor \
    su-exec \
    tzdata \
    wget \
    jq \
    python3 \
    make \
    g++ \
    sqlite-dev \
    libffi-dev \
    openssl-dev \
    python3-dev \
    && rm -rf /var/cache/apk/*

ENV CXXFLAGS="-std=c++20"
ENV npm_config_cxxstd="gnu++20"
ENV npm_config_target="22.21.1"
ENV npm_config_disturl="https://nodejs.org/dist"
# NOTE: MINDWTR_CLOUD_AUTH_TOKENS_FILE is intentionally NOT set by default.
# Upstream docker/cloud/entrypoint.sh runs `install <FILE> ...` whenever the
# variable is non-empty. Setting it to a path that does not exist (e.g.
# /app/cloud_data/auth-tokens with no token configured) makes the cloud
# process exit with `install: can't stat ...` in a supervisord restart loop.
# entrypoint.sh / run.sh set it only when a readable token file exists.
ENV MINDWTR_CLOUD_DATA_DIR="/share/mindwtr"
ENV MINDWTR_CLOUD_AUTH_TOKENS=""
ENV MINDWTR_CLOUD_AUTH_TOKENS_FILE=""
ENV MINDWTR_CLOUD_CORS_ORIGIN=""
ENV MINDWTR_CLOUD_MAX_BODY_BYTES="2000000"
ENV MINDWTR_CLOUD_MAX_ATTACHMENT_BYTES="50000000"
ENV MINDWTR_DEFAULT_CLOUD_URL=""

# Clone Mindwtr source at specific version
WORKDIR /usr/share/mindwtr
RUN git clone --depth 1 --branch v1.3.1 https://github.com/dongdongbh/Mindwtr.git . && \
    rm -rf .git

# Copy cloud entrypoint and runtime script
COPY run.sh /usr/local/bin/mindwtr-cloud-run
COPY entrypoint.sh /usr/local/bin/mindwtr-entrypoint
RUN cp docker/cloud/entrypoint.sh /usr/local/bin/mindwtr-cloud-entrypoint && \
    chmod +x /usr/local/bin/mindwtr-cloud-entrypoint && \
    chmod +x /usr/local/bin/mindwtr-cloud-run && \
    chmod +x /usr/local/bin/mindwtr-entrypoint

# Install all dependencies (including dev deps for build)
RUN bun install --frozen-lockfile

# Build the app PWA assets
RUN bun desktop:web:build

# Create app directory structure (persist cloud data under /share via HA mapping)
RUN mkdir -p /usr/share/nginx/html /app/cloud_data /share/mindwtr /data

# Copy built app assets to nginx directory
RUN cp -r apps/desktop/dist/* /usr/share/nginx/html/

# Create runtime config script
RUN mkdir -p /docker-entrypoint.d && \
    echo '#!/bin/sh' > /docker-entrypoint.d/10-runtime-config.sh && \
    echo 'set -eu' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo 'CONFIG_PATH=/usr/share/nginx/html/runtime-config.json' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo 'if [ -n "${MINDWTR_DEFAULT_CLOUD_URL:-}" ]; then' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo '    escaped=$(printf "%s" "$MINDWTR_DEFAULT_CLOUD_URL" | sed "s/\\\\/\\\\\\\\/g; s/"/\\\\"/g")' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo '    printf "{\"defaultCloudUrl\":\"%s\"}\n" "$escaped" > "$CONFIG_PATH"' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo 'else' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo '    rm -f "$CONFIG_PATH"' >> /docker-entrypoint.d/10-runtime-config.sh && \
    echo 'fi' >> /docker-entrypoint.d/10-runtime-config.sh && \
    chmod +x /docker-entrypoint.d/10-runtime-config.sh

# Set up cloud data directory (bun uid 1000 in oven/bun image)
RUN mkdir -p /app/cloud_data /share/mindwtr && chown -R bun:bun /app/cloud_data /share/mindwtr /usr/share/nginx/html /data 2>/dev/null || chown -R 1000:1000 /app/cloud_data /share/mindwtr /usr/share/nginx/html /data

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Ensure nginx user exists
RUN addgroup -S nginx 2>/dev/null; adduser -S -G nginx nginx 2>/dev/null; true

# Clean up temporary build files (keep source for bun run)
RUN rm -rf /tmp/build 2>/dev/null || true

EXPOSE 8787/tcp 8080/tcp

# Web UI always runs; the cloud server only runs in sync_mode=selfhosted
# with a token configured (see entrypoint.sh / run.sh).
HEALTHCHECK --interval=1m30s --timeout=10s --start-period=30s --retries=3 \
    CMD sh -c 'curl -fsS http://localhost:8080/ >/dev/null || exit 1; if [ "${SYNC_MODE:-local}" = "selfhosted" ] && [ -n "${MINDWTR_CLOUD_AUTH_TOKENS:-}" ]; then curl -fsS http://localhost:8787/ready >/dev/null || curl -fsS http://localhost:8787/health >/dev/null || exit 1; fi'

ENTRYPOINT ["/usr/local/bin/mindwtr-entrypoint"]
