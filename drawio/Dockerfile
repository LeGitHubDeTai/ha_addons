ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG DRAWIO_VERSION=31.4.4

RUN apk add --no-cache unzip curl

RUN mkdir -p /usr/share/nginx/html && \
    curl -fsSL -A "Mozilla/5.0" -o /tmp/draw.war "https://github.com/jgraph/drawio/releases/download/v${DRAWIO_VERSION}/draw.war" && \
    unzip /tmp/draw.war -d /usr/share/nginx/html && \
    rm /tmp/draw.war

EXPOSE 80