ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

# Install Node.js and dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    g++ \
    make \
    python3 \
    libc6-compat \
    wget \
    unzip

# Download and extract Drawnix
RUN wget https://github.com/plait-board/drawnix/archive/refs/tags/v0.3.0.zip -O drawnix.zip && \
    unzip drawnix.zip && \
    mv drawnix-0.3.0 /app && \
    rm drawnix.zip

WORKDIR /app

COPY vite.config.js ./apps/web/

# Installer dépendances
RUN npm install --ignore-scripts --omit=optional

# Copy entrypoint script
COPY drawnix-entrypoint.sh /app/drawnix-entrypoint.sh
RUN chmod +x /app/drawnix-entrypoint.sh

EXPOSE 7200

CMD ["/app/drawnix-entrypoint.sh"]
