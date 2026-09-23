ARG PENPOT_VERSION=2.18

FROM penpotapp/backend:${PENPOT_VERSION} AS penpot-backend
FROM penpotapp/frontend:${PENPOT_VERSION} AS penpot-frontend
FROM penpotapp/exporter:${PENPOT_VERSION} AS penpot-exporter
FROM penpotapp/mcp:${PENPOT_VERSION} AS penpot-mcp

FROM debian:trixie-slim

ARG BUILD_VERSION
ARG BUILD_ARCH
ARG PENPOT_VERSION=2.18

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.source="https://github.com/penpot/penpot" \
  org.opencontainers.image.description="Penpot - Open-source design & prototyping platform"

ENV LANG='C.UTF-8' \
    LC_ALL='C.UTF-8' \
    JAVA_HOME="/opt/jre" \
    PATH=/opt/jre/bin:/opt/imagick/bin:/usr/local/bin:$PATH \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LD_LIBRARY_PATH=/opt/imagick/lib/deps \
    PLAYWRIGHT_BROWSERS_PATH=/opt/penpot/browsers \
    PENPOT_VERSION=${PENPOT_VERSION}

USER root

# ===============================
# SYSTEM DEPENDENCIES
# ===============================
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        gettext-base \
        nginx \
        supervisor \
        postgresql-client \
        valkey \
        openssl \
        locales \
        passwd \
        python3 \
        # --- backend runtime libs (from official Dockerfile.backend) ---
        fontconfig \
        fontforge \
        libfontconfig1 \
        libfreetype6 \
        libglib2.0-0 \
        libgomp1 \
        libheif1 \
        libjpeg62-turbo \
        liblcms2-2 \
        libopenexr-3-1-30 \
        libopenjp2-7 \
        libpng16-16 \
        librsvg2-2 \
        libtiff6 \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        libxml2 \
        libzip5 \
        libzstd1 \
        tzdata \
        woff-tools \
        woff2 \
        python3-tabulate \
        # --- exporter (playwright/chromium) libs (from Dockerfile.exporter) ---
        xvfb \
        fonts-noto-color-emoji \
        fonts-unifont \
        xfonts-cyrillic \
        xfonts-scalable \
        fonts-liberation \
        fonts-ipafont-gothic \
        fonts-wqy-zenhei \
        fonts-tlwg-loma-otf \
        fonts-freefont-ttf \
        poppler-utils \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libx11-6 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
    ; \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; \
    locale-gen || true; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# ===============================
# NODEJS 24 (for exporter + mcp)
# ===============================
RUN set -ex; \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    node --version; npm --version; \
    apt-get clean; rm -rf /var/lib/apt/lists/*

# ===============================
# PENPOT USER
# ===============================
RUN groupadd -f -g 1001 penpot || true; \
    id penpot >/dev/null 2>&1 || useradd -M -u 1001 -s /bin/false -d /opt/penpot -g penpot penpot

# ===============================
# COPY PENPOT BUNDLES FROM OFFICIAL IMAGES
# ===============================
# Backend: JRE + imagemagick + app bundle
COPY --from=penpot-backend /opt/jre /opt/jre
COPY --from=penpot-backend /opt/imagick /opt/imagick
COPY --from=penpot-backend /opt/penpot/backend /opt/penpot/backend
# Frontend: static assets + nginx templates
COPY --from=penpot-frontend /var/www/app /var/www/app
COPY --from=penpot-frontend /tmp/nginx.conf.template /tmp/penpot-nginx.conf.template
COPY --from=penpot-frontend /tmp/resolvers.conf.template /tmp/penpot-resolvers.conf.template
# Optional templates (may be renamed/removed upstream): copy only if present
RUN --mount=from=penpot-frontend,src=/tmp,dst=/tmp/pf-tmp \
    if [ -f /tmp/pf-tmp/nginx-mcp-locations.conf.template ]; then cp -a /tmp/pf-tmp/nginx-mcp-locations.conf.template /tmp/penpot-mcp-locations.conf.template; echo "mcp template copied"; else echo "mcp template absent, skipping"; fi
COPY --from=penpot-frontend /etc/nginx/nginx-security-headers.conf /etc/nginx/nginx-security-headers.conf
COPY --from=penpot-frontend /etc/nginx/mime.types /etc/nginx/penpot-mime.types
COPY --from=penpot-frontend /etc/nginx/overrides/location.d/external-locations.conf /etc/nginx/overrides/location.d/external-locations.conf
# Exporter: node app + browsers (browsers dir may vary, copy conditionally)
COPY --from=penpot-exporter /opt/penpot/exporter /opt/penpot/exporter
RUN --mount=from=penpot-exporter,src=/opt/penpot,dst=/tmp/exp-penpot \
    if [ -d /tmp/exp-penpot/browsers ]; then cp -a /tmp/exp-penpot/browsers /opt/penpot/browsers; fi; \
    chown -R penpot:penpot /opt/penpot 2>/dev/null || true
# MCP: node app
COPY --from=penpot-mcp /opt/penpot/mcp /opt/penpot/mcp

# Frontend overrides dirs (as in official image)
RUN mkdir -p /etc/nginx/overrides/main.d \
             /etc/nginx/overrides/http.d \
             /etc/nginx/overrides/server.d \
             /etc/nginx/overrides/assets.d \
             /etc/nginx/overrides/location.d \
             /opt/data/assets \
             /run/nginx \
             /tmp/cache /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp; \
    chown -R penpot:penpot /opt/penpot /opt/data /var/www; \
    chown -R penpot:penpot /var/cache/nginx /etc/nginx /tmp/cache 2>/dev/null || true; \
    chmod -R g+w /var/cache/nginx /etc/nginx /var/www 2>/dev/null || true

# ===============================
# ADDON SCRIPTS & CONFIG
# ===============================
COPY supervisord.conf /etc/supervisord.conf
COPY hass-nginx.conf /etc/nginx/hass-nginx.conf.template
COPY valkey-entrypoint.sh /app/valkey-entrypoint.sh
COPY backend-entrypoint.sh /app/backend-entrypoint.sh
COPY exporter-entrypoint.sh /app/exporter-entrypoint.sh
COPY mcp-entrypoint.sh /app/mcp-entrypoint.sh
COPY frontend-entrypoint.sh /app/frontend-entrypoint.sh
COPY hass-nginx-entrypoint.sh /app/hass-nginx-entrypoint.sh
COPY penpot-env.sh /app/penpot-env.sh

RUN chmod +x /app/*.sh; \
    mkdir -p /data/penpot/assets /var/lib/valkey; \
    chown -R penpot:penpot /data/penpot/assets /opt/data; \
    # mime.types fallback (official path may differ on debian nginx)
    [ -f /etc/nginx/mime.types ] || cp /etc/nginx/penpot-mime.types /etc/nginx/mime.types; \
    nginx -t -c /etc/nginx/hass-nginx.conf.template 2>/dev/null || true

VOLUME ["/data"]

EXPOSE 9001 8080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
