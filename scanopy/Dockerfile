ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.20

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required packages
RUN apk add --no-cache \
    curl \
    jq \
    postgresql \
    postgresql-client \
    nginx \
    nmap \
    nmap-scripts \
    docker \
    && rm -rf /var/cache/apk/*

# Create app directories
RUN mkdir -p /data/scanopy \
    && mkdir -p /var/log/scanopy \
    && mkdir -p /etc/s6-overlay/s6-rc.d/init

# Download and install Scanopy daemon using installation script logic
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64) ARCH="amd64" ;; \
        aarch64|arm64) ARCH="arm64" ;; \
        *) echo "Error: Unsupported architecture: $ARCH" && exit 1 ;; \
    esac \
    && PLATFORM="linux" \
    && BINARY_NAME="scanopy-daemon-${PLATFORM}-${ARCH}" \
    && BINARY_URL="https://github.com/scanopy/scanopy/releases/latest/download/${BINARY_NAME}" \
    && echo "Installing Scanopy daemon..." \
    && echo "Platform: $PLATFORM" \
    && echo "Architecture: $ARCH" \
    && echo "Binary: $BINARY_NAME" \
    && echo "Downloading from: $BINARY_URL" \
    && curl -fL "$BINARY_URL" -o /tmp/scanopy-daemon \
    && chmod +x /tmp/scanopy-daemon \
    && mkdir -p /opt/scanopy \
    && mv /tmp/scanopy-daemon /opt/scanopy/ \
    && echo "✓ Scanopy daemon installed successfully!"

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY init-db.sh /scripts/
COPY scanopy-server.sh /etc/s6-overlay/s6-rc.d/init/
COPY scanopy-daemon.sh /etc/s6-overlay/s6-rc.d/init/

# Make scripts executable
RUN chmod +x /scripts/*.sh /etc/s6-overlay/s6-rc.d/init/*.sh

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

# s6-overlay will automatically start services in /etc/s6-overlay/s6-rc.d/init/
