ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

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

# Create data directory with proper permissions
RUN mkdir -p /data/scans /data/db /share/scanopy && \
    chown -R scanopy:scanopy /app /data /share

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
