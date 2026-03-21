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
    rust \
    cargo \
    nodejs \
    npm \
    make \
    go \
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

# Download and extract Scanopy source
RUN echo "Downloading Scanopy source..." \
    && curl -L "https://github.com/scanopy/scanopy/archive/refs/tags/v0.14.19.zip" -o /tmp/scanopy.zip \
    && cd /tmp \
    && unzip scanopy.zip \
    && mv scanopy-0.14.19 /opt/scanopy-src \
    && rm -rf /tmp/scanopy.zip

# Build Scanopy server
RUN echo "Building Scanopy server..." \
    && cd /opt/scanopy-src \
    && echo "Installing dependencies..." \
    && npm install --prefix ui \
    && echo "Building UI..." \
    && npm run build --prefix ui \
    && echo "Building server binary..." \
    && CGO_ENABLED=0 GOOS=linux GOARCH=$(uname -m) go build -ldflags="-s -w" -o /opt/scanopy-server ./cmd/server \
    && echo "✓ Scanopy server built successfully!" \
    && chmod +x /opt/scanopy-server

# Copy UI to deployment location
RUN cp -r /opt/scanopy-src/ui /opt/scanopy-ui \
    && rm -rf /opt/scanopy-src

# Create directories
RUN mkdir -p /data/scanopy/daemon_config \
    && mkdir -p /var/log/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh

# Make scripts executable
RUN chmod +x /run.sh

# Expose ports
EXPOSE 60072 60073

# Set environment variables
ENV SCANOPY_LOG_LEVEL=info

CMD ["/run.sh"]
