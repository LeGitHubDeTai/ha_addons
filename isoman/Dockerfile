ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    ca-certificates \
    tzdata \
    su-exec \
    wget \
    unzip \
    bash \
    git

# ---- INSTALL ISOMAN ----
RUN wget https://github.com/aloks98/isoman/archive/refs/tags/v0.3.3.zip -O isoman.zip && \
    unzip isoman.zip && \
    mv isoman-0.3.3 /app && \
    rm isoman.zip

WORKDIR /app

# ---- BUILD FRONTEND ----
FROM oven/bun:1-alpine AS frontend-builder
WORKDIR /build/ui
COPY --from=0 /app/ui/package.json /app/ui/bun.lock ./
RUN bun install --frozen-lockfile
COPY --from=0 /app/ui ./
RUN bun run build

# ---- BUILD BACKEND ----
FROM golang:1.24-alpine AS backend-builder
WORKDIR /build
RUN apk add --no-cache git
COPY --from=0 /app/go.mod /app/go.sum ./
RUN go mod download
COPY --from=0 /app/backend ./backend
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./backend

# ---- FINAL IMAGE ----
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    nginx \
    supervisor \
    ca-certificates \
    tzdata \
    su-exec

# Create user
RUN addgroup -g 1000 isoman && \
    adduser -D -u 1000 -G isoman isoman

WORKDIR /app

# Copy app
COPY --from=backend-builder /build/server ./server
COPY --from=frontend-builder /build/ui/dist ./ui/dist
COPY --from=backend-builder /build/backend/migrations ./migrations

# Create data dir
RUN mkdir -p /data && \
    chown -R isoman:isoman /app /data

# ---- NGINX CONFIG ----
COPY nginx.conf /etc/nginx/nginx.conf

# ---- SUPERVISOR ----
COPY supervisord.conf /etc/supervisord.conf

# ---- ENV ----
ENV PORT=8080
ENV DATA_DIR=/data
ENV GIN_MODE=release

EXPOSE 50145

# ---- START ----
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
