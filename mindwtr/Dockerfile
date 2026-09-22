ARG BUILD_FROM=ghcr.io/dongdongbh/mindwtr-cloud:latest
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM $BUILD_FROM AS cloud-base

FROM ghcr.io/dongdongbh/mindwtr-app:latest AS app-stage

FROM cloud-base
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache \
    nginx \
    supervisor \
    su-exec \
    ca-certificates \
    tzdata \
    curl

RUN addgroup -S nginx 2>/dev/null; adduser -S -G nginx nginx 2>/dev/null; true

COPY --from=app-stage /usr/share/nginx/html /usr/share/nginx/html
COPY --from=app-stage /docker-entrypoint.d /docker-entrypoint.d

RUN mkdir -p /data && chmod -R 755 /usr/share/nginx/html
RUN chmod +x /docker-entrypoint.d/*.sh 2>/dev/null || true

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
