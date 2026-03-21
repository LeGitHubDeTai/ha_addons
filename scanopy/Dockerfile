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
    git \
    ca-certificates \
    gnupg2 \
    wget \
    unzip \
    && rm -rf /var/cache/apk/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Install NVM and Node.js 20
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
ENV NVM_DIR="/root/.nvm"
RUN bash -c '. $NVM_DIR/nvm.sh && nvm install 20 && nvm use 20 && nvm alias default 20'
ENV PATH="/root/.nvm/versions/node/v20.*/bin:$PATH"

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
    && echo "Downloading daemon from: $BINARY_URL" \
    && curl -fL "$BINARY_URL" -o /opt/scanopy-daemon \
    && chmod +x /opt/scanopy-daemon \
    && echo "✓ Scanopy daemon installed successfully!"

# Download and build Scanopy server from source
RUN echo "Building Scanopy server from source..." \
    && curl -L "https://github.com/scanopy/scanopy/archive/refs/tags/v0.14.19.zip" -o /tmp/scanopy.zip \
    && cd /tmp \
    && unzip scanopy.zip \
    && mv scanopy-0.14.19 scanopy \
    && cd scanopy \
    && echo "Installing development dependencies..." \
    && bash -c '. $NVM_DIR/nvm.sh && nvm use 20 && make install-dev-linux' \
    && echo "Building server..." \
    && bash -c '. $NVM_DIR/nvm.sh && nvm use 20 && make build-server' \
    && echo "Building UI..." \
    && bash -c '. $NVM_DIR/nvm.sh && nvm use 20 && make build-ui' \
    && echo "✓ Scanopy server built successfully!" \
    && cp ./bin/scanopy-server /opt/scanopy-server \
    && chmod +x /opt/scanopy-server \
    && rm -rf /tmp/scanopy /tmp/scanopy.zip

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
