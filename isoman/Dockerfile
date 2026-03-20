ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root

# Install dependencies including Go for building
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    supervisor \
    jq \
    git \
    wget

# Install Go 1.23 (newer than Alpine's default)
RUN case "${BUILD_ARCH}" in \
        "amd64") GO_ARCH="amd64" ;; \
        "armhf") GO_ARCH="armv6l" ;; \
        "armv7") GO_ARCH="armv6l" ;; \
        "aarch64") GO_ARCH="arm64" ;; \
        "i386") GO_ARCH="386" ;; \
        *) GO_ARCH="amd64" ;; \
    esac && \
    wget -O /tmp/go.tar.gz "https://go.dev/dl/go1.23.4.linux-${GO_ARCH}.tar.gz" && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz && \
    ln -sf /usr/local/go/bin/go /usr/bin/go

# Create directories
RUN mkdir -p /data/isoman \
    && mkdir -p /var/log/supervisor

WORKDIR /data

# Clone and build Isoman from source
RUN git clone https://github.com/aloks98/isoman.git /tmp/isoman-src && \
    cd /tmp/isoman-src && \
    git checkout v0.3.1 && \
    cd backend && \
    go mod download && \
    go build -ldflags="-w -s" -o /usr/local/bin/isoman . && \
    rm -rf /tmp/isoman-src

# Make sure the binary is executable
RUN chmod +x /usr/local/bin/isoman

# Copy configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY isoman-entrypoint.sh /app/isoman-entrypoint.sh

RUN chmod +x /app/isoman-entrypoint.sh

# Expose port
EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
