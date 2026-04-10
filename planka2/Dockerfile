ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
ARG BUILD_VERSION=26.4.2.27
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
# DOWNLOAD PLANKA PREBUILD
# ===============================
ARG PLANKA_VERSION=2.1.0
RUN wget -O planka-prebuild.zip "https://github.com/plankanban/planka/releases/download/v${PLANKA_VERSION}/planka-prebuild.zip" \
    && unzip planka-prebuild.zip \
    && rm planka-prebuild.zip \
    && mv planka /tmp/planka-source

# ===============================
# SETUP PLANKA FINAL
# ===============================
WORKDIR /opt/planka
RUN cp -r /tmp/planka-source/* . \
    && npm install \
    && python3 -m venv .venv \
    && .venv/bin/pip3 install --upgrade pip \
    && (if [ -f requirements.txt ]; then .venv/bin/pip3 install -r requirements.txt --no-cache-dir; else echo "No requirements.txt found, skipping Python dependencies"; fi) \
    && (if [ -f .env.sample ]; then mv .env.sample .env; else echo "No .env.sample found, creating empty .env"; touch .env; fi) \
    && mkdir -p server/views \
    && (if [ -f public/index.ejs ]; then cp public/index.ejs server/views/; elif [ -f client/dist/index.ejs ]; then cp client/dist/index.ejs server/views/; else echo "Creating basic index.ejs template"; echo '<!DOCTYPE html><html><head><title>Planka</title></head><body><div id="root"></div></body></html>' > server/views/index.ejs; fi) \
    && npm config set update-notifier false \
    && rm -rf /tmp/planka-source

# ===============================
# COPY CONFIGURATION FILES
# ===============================
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /opt/planka/run.sh
COPY start.sh /opt/planka/start.sh

# ===============================
# PERMISSIONS
# ===============================
RUN chmod +x /opt/planka/run.sh && \
    chmod +x /opt/planka/start.sh && \
    chown -R root:root /opt/planka && \
    chown -R nginx:nginx /var/log/nginx

# ===============================
# SET WORKING DIRECTORY
# ===============================
WORKDIR /opt/planka

# ===============================
# CREATE LOGS DIRECTORY
# ===============================
RUN mkdir -p /var/log/supervisor /var/log/nginx && \
    chown -R root:root /var/log/supervisor && \
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
