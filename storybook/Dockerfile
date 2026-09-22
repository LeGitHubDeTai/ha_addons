ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG STORYBOOK_VERSION=10.6.0
FROM ${BUILD_FROM}

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache \
    nodejs \
    npm \
    wget \
    unzip \
    bash \
    ca-certificates \
    tzdata \
    g++ \
    make \
    python3 \
    libc6-compat \
    nginx \
    supervisor

RUN mkdir -p /storybook-project && cd /storybook-project && \
    npm init -y && \
    npx storybook@${STORYBOOK_VERSION} init --yes --type react --builder vite --package-manager npm --no-dev && \
    npm run build-storybook

RUN mkdir -p /usr/share/nginx/html && \
    cp -r /storybook-project/storybook-static/. /usr/share/nginx/html/ && \
    rm -rf /storybook-project

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /etc/supervisord.conf

EXPOSE 6006

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
