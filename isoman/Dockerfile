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
    go \
    git

# Create directories
RUN mkdir -p /data/isoman \
    && mkdir -p /var/log/supervisor

WORKDIR /data

# Clone and build Isoman from source
RUN git clone https://github.com/aloks98/isoman.git /tmp/isoman-src && \
    cd /tmp/isoman-src && \
    git checkout v0.3.1 && \
    cd backend && \
    # Fix Go version compatibility for Alpine
    sed -i 's/go 1.24.4/go 1.23/' go.mod && \
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
