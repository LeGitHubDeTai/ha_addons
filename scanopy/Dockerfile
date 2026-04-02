ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Install build dependencies
RUN apk add --no-cache \
    wget \
    unzip \
    bash \
    ca-certificates \
    tzdata \
    su-exec \
    gcc \
    musl-dev \
    pkgconfig \
    openssl-dev \
    libffi-dev \
    python3 \
    make \
    g++

# Download and extract Scanopy
RUN wget https://github.com/scanopy/scanopy/archive/refs/tags/v0.14.19.zip -O scanopy.zip && \
    unzip scanopy.zip && \
    mv scanopy-0.14.19 /builder && \
    rm scanopy.zip

WORKDIR /builder

# Install Rust
RUN wget --quiet -O- https://sh.rustup.rs | bash -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup default stable

# Stage 1: Build backend
FROM ${BUILD_FROM} AS backend-builder

# Install build dependencies for Rust
RUN apk add --no-cache \
    gcc \
    musl-dev \
    pkgconfig \
    openssl-dev \
    libffi-dev \
    python3 \
    make \
    g++

# Install Rust
RUN wget --quiet -O- https://sh.rustup.rs | bash -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup default stable

# Copy source from first stage
COPY --from=0 /builder /builder
WORKDIR /builder/backend

# Build backend
RUN . "$HOME/.cargo/env" && \
    cargo build --release --bin server && \
    cargo build --release --bin generate-fixtures

# Generate fixtures for UI
RUN . "$HOME/.cargo/env" && \
    ./target/release/generate-fixtures --output-dir /fixtures

# Stage 2: Build UI
FROM node:20-slim AS ui-builder

WORKDIR /app/ui

# Copy UI source
COPY --from=backend-builder /builder/ui/ ./

# Copy messages and fixtures
COPY --from=backend-builder /builder/messages/ ../messages/
COPY --from=backend-builder /fixtures/ ./src/lib/data/

# Install dependencies and build
RUN npm ci && \
    npm run build

# Stage 3: Runtime Image
FROM ${BUILD_FROM}

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    su-exec \
    wget \
    supervisor \
    nginx \
    curl

COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user
RUN addgroup -g 1000 scanopy && \
    adduser -D -u 1000 -G scanopy scanopy

WORKDIR /app

# Copy server binary from builder
COPY --from=backend-builder /builder/backend/target/release/server ./server

# Copy UI static files from builder
COPY --from=ui-builder /app/ui/build ./static

# Verify server binary exists
RUN test -f ./server || (echo "Server binary not found!" && exit 1) && \
    chmod +x ./server

# Create data directory with proper permissions
RUN mkdir -p /data/scans /data/db /share/scanopy && \
    chown -R scanopy:scanopy /app /data /share

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /etc/supervisord.conf

# Copy startup script
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Set environment variables
ENV SCANOPY_SERVER_PORT=60072
ENV DATA_DIR=/share/scanopy

EXPOSE 60072

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:60072/api/health || exit 1

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
