ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.20

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required packages
RUN apk add --no-cache \
    curl \
    jq \
    postgresql-client \
    supervisor \
    nginx \
    && rm -rf /var/cache/apk/*

# Create app directories
RUN mkdir -p /data/scanopy \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /var/log/nginx

# Copy configuration files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY scanopy-entrypoint.sh /scripts/
COPY nginx-entrypoint.sh /scripts/

# Make scripts executable
RUN chmod +x /scripts/*.sh

# Create data directory structure
RUN mkdir -p /data/scanopy/postgres_data \
    && mkdir -p /data/scanopy/daemon_config \
    && mkdir -p /data/scanopy/static

# Expose ports
EXPOSE 60072 60073

# Set environment variables
ENV SCANOPY_LOG_LEVEL=info
ENV SCANOPY_SERVER_URL=http://127.0.0.1:60072
ENV SCANOPY_PUBLIC_URL=http://localhost:60072
ENV POSTGRES_DB=scanopy
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV SCANOPY_DATABASE_URL=postgresql://postgres:password@localhost:5432/scanopy
ENV SCANOPY_WEB_EXTERNAL_PATH=/app/static
ENV SCANOPY_INTEGRATED_DAEMON_URL=http://localhost:60073

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
