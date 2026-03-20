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
    git \
    nodejs \
    npm \
    g++ \
    make \
    python3 \
    libc6-compat

# Clone repo
RUN git clone https://github.com/plait-board/drawnix.git /app

WORKDIR /app

COPY vite.config.js ./apps/web/

# Installer dépendances
RUN npm config set optional false && \
    npm install --ignore-scripts --no-optional

# Build production
RUN npm run build

EXPOSE 7200

CMD ["npm", "start"]
