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
    nodejs \
    npm \
    wget \
    unzip \
    bash \
    g++ \
    make \
    python3 \
    libc6-compat || true

# Download and extract Drawnix
RUN wget https://github.com/plait-board/drawnix/archive/refs/tags/v0.3.0.zip -O drawnix.zip && \
    unzip drawnix.zip && \
    mv drawnix-0.3.0 /builder && \
    rm drawnix.zip

WORKDIR /builder

# Install dependencies and build
RUN npm install && \
    npm run build

# Install nginx and supervisord for serving
RUN apk add --no-cache \
    nginx \
    supervisor

# Copy built files to nginx location
RUN mkdir -p /usr/share/nginx/html && \
    cp -r /builder/dist/apps/web/* /usr/share/nginx/html/ && \
    echo "=== Final nginx html directory ===" && \
    ls -la /usr/share/nginx/html/ && \
    echo "=== Setting proper permissions ===" && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Copy configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod +x /etc/supervisord.conf

EXPOSE 7200

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
