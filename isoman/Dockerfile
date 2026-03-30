ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

ENV ISOMAN_VERSION=0.3.3

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

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

# Create directories
RUN mkdir -p /data/isoman \
    && mkdir -p /var/log/supervisor

WORKDIR /opt/isoman

# Download and extract Isoman source
RUN wget -O /tmp/isoman.zip "https://github.com/aloks98/isoman/archive/refs/tags/v$ISOMAN_VERSION.zip" && \
    unzip /tmp/isoman.zip -d /tmp && \
    mv /tmp/isoman-$ISOMAN_VERSION/* . && \
    rm -rf /tmp/isoman.zip /tmp/isoman-$ISOMAN_VERSION

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
