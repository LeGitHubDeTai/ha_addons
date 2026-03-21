ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root

# Install dependencies including Go and Bun for building
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    supervisor \
    jq \
    git \
    wget \
    unzip

# Install Go 1.23
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

# Install Bun
RUN case "${BUILD_ARCH}" in \
        "amd64") BUN_ARCH="x64" ;; \
        "armhf") BUN_ARCH="armv6" ;; \
        "armv7") BUN_ARCH="armv6" ;; \
        "aarch64") BUN_ARCH="arm64" ;; \
        "i386") BUN_ARCH="x64" ;; \
        *) BUN_ARCH="x64" ;; \
    esac && \
    wget -O /tmp/bun.zip "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${BUN_ARCH}.zip" && \
    unzip /tmp/bun.zip -d /tmp && \
    mv /tmp/bun-linux-${BUN_ARCH}/bun /usr/local/bin/ && \
    rm -rf /tmp/bun.zip /tmp/bun-linux-${BUN_ARCH}

# Create directories
RUN mkdir -p /data/isoman \
    && mkdir -p /var/log/supervisor

WORKDIR /data

# Download and extract Isoman
RUN wget -O /tmp/isoman.zip "https://github.com/aloks98/isoman/archive/refs/tags/v0.3.3.zip" && \
    unzip /tmp/isoman.zip -d /tmp && \
    mv /tmp/isoman-0.3.3 /opt/isoman && \
    rm -rf /tmp/isoman.zip

# Build Go backend
RUN cd /opt/isoman/backend && \
    go mod download && \
    go build -ldflags="-w -s" -o /usr/local/bin/isoman .

# Build frontend with Bun
RUN cd /opt/isoman/ui && \
    /usr/local/bin/bun install && \
    /usr/local/bin/bun run build

# Copy configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY isoman-entrypoint.sh /app/isoman-entrypoint.sh

RUN chmod +x /app/isoman-entrypoint.sh

# Expose port
EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
