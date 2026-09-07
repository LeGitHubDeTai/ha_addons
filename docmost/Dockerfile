ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    nginx \
    supervisor \
    envsubst \
    python3 \
    make \
    g++ \
    postgresql16 \
    postgresql16-client \
    redis

# Install Node.js 22 LTS
RUN apk add --no-cache nodejs npm || \
    (curl -fsSL https://dl-cdn.alpinelinux.org/alpine/v3.22/community/x86_64/APKINDEX.tar.gz | tar xz -C /tmp && \
     apk add --no-cache nodejs npm)

# Create directories
RUN mkdir -p /run/nginx /data/docmost/data/storage /data/docmost/log \
    /var/lib/postgresql/data /var/lib/redis

# Set correct permissions for directories
RUN chown -R postgres:postgres /var/lib/postgresql/data \
    && chown -R redis:redis /var/lib/redis

# Download Docmost
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -fsSL -o /tmp/docmost.tar.gz \
        "https://github.com/docmost/docmost/releases/latest/download/docmost-linux-${ARCH}.tar.gz" && \
    mkdir -p /opt/docmost && \
    tar -xzf /tmp/docmost.tar.gz -C /opt/docmost --strip-components=1 && \
    rm /tmp/docmost.tar.gz

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY supervisord.conf /etc/supervisord.conf
COPY nginx-entrypoint.sh /app/nginx-entrypoint.sh
COPY docmost-entrypoint.sh /app/docmost-entrypoint.sh

RUN chmod +x /app/nginx-entrypoint.sh /app/docmost-entrypoint.sh

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
