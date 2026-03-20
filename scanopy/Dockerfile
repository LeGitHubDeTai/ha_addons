ARG BUILD_FROM
FROM ${BUILD_FROM}

# Disable s6-overlay by removing the entrypoint
ENTRYPOINT []

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required packages
RUN apk add --no-cache \
    curl \
    jq \
    nginx \
    nmap \
    nmap-scripts \
    bash \
    && rm -rf /var/cache/apk/*

# Download and install Scanopy daemon and server
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64) ARCH="amd64" ;; \
        aarch64|arm64) ARCH="arm64" ;; \
        *) echo "Error: Unsupported architecture: $ARCH" && exit 1 ;; \
    esac \
    && PLATFORM="linux" \
    && BINARY_NAME="scanopy-daemon-${PLATFORM}-${ARCH}" \
    && SERVER_NAME="scanopy-server-${PLATFORM}-${ARCH}" \
    && BINARY_URL="https://github.com/scanopy/scanopy/releases/latest/download/${BINARY_NAME}" \
    && SERVER_URL="https://github.com/scanopy/scanopy/releases/latest/download/${SERVER_NAME}" \
    && echo "Installing Scanopy daemon..." \
    && echo "Platform: $PLATFORM" \
    && echo "Architecture: $ARCH" \
    && echo "Daemon Binary: $BINARY_NAME" \
    && echo "Server Binary: $SERVER_NAME" \
    && echo "Downloading daemon from: $BINARY_URL" \
    && echo "Downloading server from: $SERVER_URL" \
    && curl -fL "$BINARY_URL" -o /opt/scanopy-daemon \
    && curl -fL "$SERVER_URL" -o /opt/scanopy-server \
    && chmod +x /opt/scanopy-daemon \
    && chmod +x /opt/scanopy-server \
    && echo "✓ Scanopy daemon and server installed successfully!"

# Create directories
RUN mkdir -p /data/scanopy/daemon_config \
    && mkdir -p /data/scanopy/static \
    && mkdir -p /var/log/scanopy \
    && mkdir -p /scripts

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh

# Make scripts executable
RUN chmod +x /run.sh

# Expose ports
EXPOSE 60072 60073

# Set environment variables
ENV SCANOPY_LOG_LEVEL=info
ENV SCANOPY_SERVER_URL=http://127.0.0.1:60072
ENV SCANOPY_PUBLIC_URL=http://localhost:60072
ENV SCANOPY_WEB_EXTERNAL_PATH=/app/static
ENV SCANOPY_INTEGRATED_DAEMON_URL=http://localhost:60073

CMD ["/run.sh"]
