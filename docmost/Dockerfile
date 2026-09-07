# Use the official Docmost image as base (Debian-based)
FROM docmost/docmost:latest

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root

# Install additional dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    nginx \
    supervisor \
    postgresql \
    postgresql-client \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /run/nginx /data/docmost/data/storage /data/docmost/log \
    /var/lib/postgresql/data /var/lib/redis

# Set correct permissions
RUN chown -R postgres:postgres /var/lib/postgresql/data \
    && chown -R redis:redis /var/lib/redis

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY supervisord.conf /etc/supervisord.conf
COPY nginx-entrypoint.sh /app/nginx-entrypoint.sh
COPY docmost-entrypoint.sh /app/docmost-entrypoint.sh

RUN chmod +x /app/nginx-entrypoint.sh /app/docmost-entrypoint.sh

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
