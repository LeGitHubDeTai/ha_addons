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
    su-exec

# Download and extract Scanopy
RUN wget https://github.com/scanopy/scanopy/archive/refs/tags/v0.14.19.zip -O scanopy.zip && \
    unzip scanopy.zip && \
    mv scanopy-0.14.19 /builder && \
    rm scanopy.zip

WORKDIR /builder

# Stage 1: Build Rust backend
FROM lukemathwalker/cargo-chef:latest-rust-1.90 AS chef
WORKDIR /app

FROM chef AS planner
COPY --from=0 /builder/backend/ .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS rust-builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY --from=0 /builder/backend/ .
RUN cargo build --release --bin server --bin generate-fixtures
RUN /app/target/release/generate-fixtures --output-dir /fixtures

# Stage 2: Build UI
FROM node:20-slim AS ui-builder
WORKDIR /app/ui
COPY --from=0 /builder/ui/package*.json ./
RUN npm ci
COPY --from=0 /builder/ui/ ./
COPY --from=0 /builder/messages/ ../messages/
COPY --from=rust-builder /fixtures/ ./src/lib/data/
ARG PUBLIC_SERVER_HOSTNAME=localhost
ARG PUBLIC_SERVER_PORT=60072
ENV PUBLIC_SERVER_HOSTNAME=$PUBLIC_SERVER_HOSTNAME
ENV PUBLIC_SERVER_PORT=$PUBLIC_SERVER_PORT
RUN npm run build

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
COPY --from=rust-builder /app/target/release/server ./server

# Copy UI static files from builder
COPY --from=ui-builder /app/ui/build ./static

# Create data directory with proper permissions
RUN mkdir -p /data/scans /data/db /share/scanopy && \
    chown -R scanopy:scanopy /app /data /share && \
    chmod +x ./server

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /etc/supervisord.conf

# Set environment variables
ENV PORT=60072
ENV DATA_DIR=/share/scanopy

EXPOSE 60072

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:60072/api/health || exit 1

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
