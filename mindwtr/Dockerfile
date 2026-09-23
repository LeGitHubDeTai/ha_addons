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
ENV MINDWTR_CLOUD_DATA_DIR="/app/cloud_data"

# Clone Mindwtr source at specific version
WORKDIR /usr/share/mindwtr
RUN git clone --depth 1 --branch v1.3.1 https://github.com/dongdongbh/Mindwtr.git . && \
    rm -rf .git

# Copy cloud entrypoint
RUN cp docker/cloud/entrypoint.sh /usr/local/bin/mindwtr-cloud-entrypoint && \
    chmod +x /usr/local/bin/mindwtr-cloud-entrypoint

# Install all dependencies (including dev deps for build)
RUN bun install --frozen-lockfile

# Build the app PWA assets
RUN bun desktop:web:build

# Create app directory structure
RUN mkdir -p /usr/share/nginx/html /app/cloud_data /data

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

# Set up cloud data directory
RUN mkdir -p /app/cloud_data && chown -R 1000:1000 /app/cloud_data /usr/share/nginx/html /data

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Ensure nginx user exists
RUN addgroup -S nginx 2>/dev/null; adduser -S -G nginx nginx 2>/dev/null; true

# Clean up temporary build files (keep source for bun run)
RUN rm -rf /tmp/build 2>/dev/null || true

EXPOSE 8787/tcp 8080/tcp

HEALTHCHECK --interval=1m30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://localhost:8787/ready >/dev/null || curl -fsS http://localhost:8787/health >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
