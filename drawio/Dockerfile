FROM ghcr.io/hassio-addons/base:21.0.0

ARG DRAWIO_VERSION=31.4.2

RUN apk add --no-cache unzip curl nginx

RUN mkdir -p /usr/share/nginx/html && \
    curl -fsSL -A "Mozilla/5.0" -o /tmp/draw.war "https://github.com/jgraph/drawio/releases/download/v${DRAWIO_VERSION}/draw.war" && \
    unzip /tmp/draw.war -d /usr/share/nginx/html && \
    rm /tmp/draw.war

COPY root /

ENTRYPOINT [ "/init" ]
CMD []
