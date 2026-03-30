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
    git \
    ca-certificates \
    tzdata \
    su-exec

# Download and extract ISOMan
RUN wget https://github.com/aloks98/isoman/archive/refs/tags/v0.3.3.zip -O isoman.zip && \
    unzip isoman.zip && \
    mv isoman-0.3.3 /builder && \
    rm isoman.zip

WORKDIR /builder

# Multi-stage build following the official Dockerfile pattern
# Stage 1: Build frontend with Bun
FROM oven/bun:1-alpine AS frontend-builder

WORKDIR /app/ui
COPY --from=0 /builder/ui/package.json /builder/ui/bun.lock ./
RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install --frozen-lockfile
COPY --from=0 /builder/ui/ ./
RUN bun run build

# Stage 2: Build backend with Go
FROM golang:1.24-alpine AS backend-builder

ARG VERSION=0.3.3
WORKDIR /app
RUN apk add --no-cache git
COPY --from=0 /builder/go.mod /builder/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
COPY --from=0 /builder/backend/ ./backend/
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s -X main.Version=${VERSION}" \
    -o server ./backend

# Stage 3: Runtime Image
FROM ${BUILD_FROM}

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    su-exec \
    wget \
    supervisor

# Create non-root user
RUN addgroup -g 1000 isoman && \
    adduser -D -u 1000 -G isoman isoman

WORKDIR /app

# Copy backend binary from builder
COPY --from=backend-builder /app/server ./server

# Copy frontend dist from builder
COPY --from=frontend-builder /app/ui/dist ./ui/dist

# Copy migrations directory from builder
COPY --from=backend-builder /app/backend/migrations ./migrations

# Copy entrypoint script
COPY --from=0 /builder/backend/docker-entrypoint.sh /entrypoint.sh

# Create data directory with proper permissions
RUN mkdir -p /data/isos /data/db && \
    chown -R isoman:isoman /app /data && \
    chmod +x /entrypoint.sh

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /etc/supervisord.conf

# Set environment variables
ENV PORT=8080
ENV DATA_DIR=/data
ENV WORKER_COUNT=2
ENV GIN_MODE=release

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
