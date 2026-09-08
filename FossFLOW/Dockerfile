ARG BUILD_FROM
FROM $BUILD_FROM

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

# Set environment variables
ENV NODE_ENV=production
ENV ENABLE_SERVER_STORAGE=true
ENV STORAGE_PATH=/data/diagrams
ENV ENABLE_GIT_BACKUP=false

# Install Node.js and dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    curl

# Install FossFLOW from upstream
ARG FOSSFLOW_VERSION=1.0.4
RUN cd /tmp \
    && curl -L "https://github.com/Abrar74774/FossFLOW/archive/refs/tags/v${FOSSFLOW_VERSION}.zip" -o fossflow.zip \
    && unzip fossflow.zip \
    && cd FossFLOW-${FOSSFLOW_VERSION} \
    && npm install \
    && npm install -g . \
    && cd / \
    && rm -rf /tmp/fossflow*

# Create directories
RUN mkdir -p /data/diagrams

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
