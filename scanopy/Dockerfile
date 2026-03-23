ARG BUILD_FROM
FROM ${BUILD_FROM}

# Disable s6-overlay to avoid PID 1 conflicts
ENV S6_KEEP_ENV=1
ENV S6_VERBOSITY=2
ENV S6_CMD_ARGS="-c"
ENTRYPOINT []

# Install required packages
RUN apk add --no-cache \
    curl \
    nginx \
    bash \
    unzip \
    jq \
    python3 \
    git \
    make \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*

# Download and install Scanopy daemon
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
    && echo "Daemon Binary: $BINARY_NAME" \
    && echo "Downloading from: $BINARY_URL" \
    && curl -fL "$BINARY_URL" -o /opt/scanopy-daemon \
    && chmod +x /opt/scanopy-daemon \
    && echo "✓ Scanopy daemon installed successfully!"

# Download and build Scanopy UI directly
RUN echo "Downloading and building Scanopy UI..." \
    && git clone https://github.com/scanopy/scanopy.git /opt/scanopy-source \
    && cd /opt/scanopy-source \
    && echo "Creating missing data files..." \
    && mkdir -p ui/src/lib/data \
    && echo '[]' > ui/src/lib/data/billing-plans.json \
    && echo '{"features": []}' > ui/src/lib/data/features.json \
    && echo '{"services": []}' > ui/src/lib/data/service-definitions.json \
    && echo "Building UI with npm..." \
    && cd ui \
    && npm install --force \
    && npm run build \
    && echo "Build completed, checking dist directory..." \
    && ls -la dist/ \
    && mv dist/* /opt/scanopy-ui/ \
    && echo "✓ Scanopy UI built and copied successfully!"

# Create directories
RUN mkdir -p /data/scanopy/daemon_config \
    && mkdir -p /var/log/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh
COPY index.html /index.html

# Make scripts executable
RUN chmod +x /run.sh

# Expose ports
EXPOSE 60072 60073

# Set environment variables
ENV SCANOPY_LOG_LEVEL=info

CMD ["/run.sh"]
