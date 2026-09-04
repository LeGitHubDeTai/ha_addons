ARG DRAWIO_VERSION=31.4.2

FROM nginx:alpine

RUN apk add --no-cache unzip

RUN mkdir -p /usr/share/nginx/html && \
    wget https://github.com/jgraph/drawio/releases/download/v${DRAWIO_VERSION}/draw.war -O /tmp/draw.war && \
    unzip /tmp/draw.war -d /usr/share/nginx/html && \
    rm /tmp/draw.war

EXPOSE 80