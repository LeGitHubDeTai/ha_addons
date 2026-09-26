ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH

FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    ffmpeg \
    jpeg \
    libffi \
    libgcc \
    libstdc++ \
    nginx \
    python3 \
    py3-pip \
    supervisor \
    tzdata

RUN pip3 install --no-cache-dir \
    yt-dlp \
    flask

RUN mkdir -p /run/nginx /var/log/supervisor /usr/share/yt-dlp

COPY supervisord.conf /etc/supervisord.conf
COPY youtube-dl-entrypoint.sh /app/youtube-dl-entrypoint.sh
COPY webapp /app/webapp
COPY nginx.conf /etc/nginx/nginx.conf

RUN chmod +x /app/youtube-dl-entrypoint.sh

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:5000/ || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]