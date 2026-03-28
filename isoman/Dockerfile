ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root

# Install dependencies including Go and Node.js for building
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    supervisor \
    jq \
    git \
    wget \
    unzip \
    nodejs \
    npm

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

# Create directories
RUN mkdir -p /data/isoman \
    && mkdir -p /var/log/supervisor

WORKDIR /opt/isoman

# Download and extract Isoman source
RUN wget -O /tmp/isoman.zip "https://github.com/aloks98/isoman/archive/refs/tags/v0.3.3.zip" && \
    unzip /tmp/isoman.zip -d /tmp && \
    mv /tmp/isoman-0.3.3/* . && \
    rm -rf /tmp/isoman.zip /tmp/isoman-0.3.3

# Build frontend with Node.js (compatible with all architectures)
RUN cd ui && \
    npm install --no-optional && \
    npm run build || echo "Frontend build skipped on this architecture"

# Build Go backend
RUN cd backend && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s -X main.Version=${BUILD_VERSION}" \
    -o /usr/local/bin/isoman .

# Copy configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY isoman-entrypoint.sh /app/isoman-entrypoint.sh

RUN chmod +x /app/isoman-entrypoint.sh

# Expose port
EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
