ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon"

# ===============================
# BASE DEPENDENCIES (Alpine)
# ===============================
RUN apk add --no-cache \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        build-base \
        python3 \
        py3-pip \
        openssl \
        nginx \
        squid \
        bash \
    && rm -rf /var/cache/apk/*

# ===============================
# INSTALL SUPERVISORD
# ===============================
RUN pip3 install --break-system-packages supervisor && \
    which supervisord

# ===============================
# INSTALL NODEJS 22
# ===============================
RUN apk add --no-cache nodejs npm

# ===============================
# CREATE DIRECTORIES
# ===============================
RUN mkdir -p /opt/planka /var/log/supervisor /var/log/nginx

# ===============================
# DOWNLOAD PLANKA SOURCE
# ===============================
ARG PLANKA_VERSION=2.1.0
RUN wget -O planka-source.zip "https://github.com/plankanban/planka/archive/refs/tags/v${PLANKA_VERSION}.zip" \
    && unzip planka-source.zip \
    && rm planka-source.zip \
    && mv planka-${PLANKA_VERSION} /tmp/planka-source

# ===============================
# BUILD PLANKA SERVER
# ===============================
WORKDIR /tmp/planka-source/server
RUN npm install npm --global \
    && npm install \
    && npm run build \
    && npm prune --production

# ===============================
# BUILD PLANKA CLIENT
# ===============================
WORKDIR /tmp/planka-source/client
RUN npm install npm --global \
    && npm install --omit=dev \
    && INDEX_FORMAT=ejs DISABLE_ESLINT_PLUGIN=true npm run build

# ===============================
# SETUP PLANKA FINAL
# ===============================
WORKDIR /opt/planka
RUN cp -r /tmp/planka-source/* . \
    && npm install \
    && python3 -m venv .venv \
    && .venv/bin/pip3 install --upgrade pip \
    && .venv/bin/pip3 install -r requirements.txt --no-cache-dir \
    && mv .env.sample .env \
    && mv public/index.ejs views \
    && npm config set update-notifier false \
    && rm -rf /tmp/planka-source

# ===============================
# COPY CONFIGURATION FILES
# ===============================
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /opt/planka/run.sh

# ===============================
# PERMISSIONS
# ===============================
RUN chmod +x /opt/planka/run.sh && \
    chown -R node:node /opt/planka && \
    chown -R nginx:nginx /var/log/nginx

# ===============================
# SET WORKING DIRECTORY
# ===============================
WORKDIR /opt/planka

# ===============================
# CREATE LOGS DIRECTORY
# ===============================
RUN mkdir -p /var/log/supervisor /var/log/nginx && \
    chown -R node:node /var/log/supervisor && \
    chown -R nginx:nginx /var/log/nginx

# ===============================
# EXPOSE PORTS
# ===============================
EXPOSE 1337 1338

# ===============================
# HEALTHCHECK
# ===============================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:1337/api/health || exit 1

# ===============================
# ENTRYPOINT
# ===============================
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
