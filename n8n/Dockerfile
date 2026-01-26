ARG BUILD_FROM
FROM $BUILD_FROM

ARG NGINX_ALLOWED_IP=172.30.32.2
ENV NGINX_ALLOWED_IP=${NGINX_ALLOWED_IP}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root
RUN apk add --no-cache \
    jq \
    bash \
    npm \
    curl \
    nginx \
    supervisor \
    envsubst
WORKDIR /data
COPY n8n-entrypoint.sh /app/n8n-entrypoint.sh

RUN npm install -g n8n@2.4.6

RUN mkdir -p /run/nginx

COPY nginx.conf /etc/nginx/nginx.conf.template

COPY n8n-exports.sh /app/n8n-exports.sh
COPY n8n-entrypoint.sh /app/n8n-entrypoint.sh
COPY nginx-entrypoint.sh /app/nginx-entrypoint.sh

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

RUN chmod +x /app/n8n-entrypoint.sh \
    && chmod +x /app/nginx-entrypoint.sh \
    && chmod +x /app/n8n-exports.sh

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
