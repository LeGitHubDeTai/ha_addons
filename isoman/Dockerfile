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
    curl \
    ca-certificates \
    tzdata \
    supervisor \
    jq \
    wget \
    unzip

# Install Node.js 20.0.0
RUN case "${BUILD_ARCH}" in \
        "amd64") NODE_ARCH="x64" ;; \
        "armhf") NODE_ARCH="armv7l" ;; \
        "armv7") NODE_ARCH="armv7l" ;; \
        "aarch64") NODE_ARCH="arm64" ;; \
        "i386") NODE_ARCH="x86" ;; \
        *) NODE_ARCH="x64" ;; \
    esac && \
    wget -O /tmp/node.tar.gz "https://nodejs.org/dist/v20.0.0/node-v20.0.0-linux-${NODE_ARCH}.tar.gz" && \
    tar -C /usr/local -xzf /tmp/node.tar.gz && \
    rm /tmp/node.tar.gz && \
    ln -sf /usr/local/node-v20.0.0-linux-${NODE_ARCH}/bin/node /usr/bin/node && \
    ln -sf /usr/local/node-v20.0.0-linux-${NODE_ARCH}/bin/npm /usr/bin/npm

# Create directories
RUN mkdir -p /data/isoman \
    && mkdir -p /var/log/supervisor

WORKDIR /data

# Download and extract Isoman
RUN wget -O /tmp/isoman.zip "https://github.com/aloks98/isoman/archive/refs/tags/v0.3.3.zip" && \
    unzip /tmp/isoman.zip -d /tmp && \
    mv /tmp/isoman-0.3.3 /opt/isoman && \
    rm -rf /tmp/isoman.zip

# Install frontend dependencies
RUN cd /opt/isoman/ui && \
    npm install && \
    npm run build

# Copy configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY isoman-entrypoint.sh /app/isoman-entrypoint.sh

RUN chmod +x /app/isoman-entrypoint.sh

# Expose port
EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
