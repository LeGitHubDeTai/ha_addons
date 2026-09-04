ARG DRAWIO_VERSION=30.0.1

FROM nginx:alpine

# Téléchargement de Draw.io version dynamique
RUN mkdir -p /usr/share/nginx/html && \
    wget https://github.com/jgraph/drawio/archive/refs/tags/v${DRAWIO_VERSION}.zip -O /tmp/drawio.zip && \
    unzip /tmp/drawio.zip -d /usr/share/nginx/html && \
    rm /tmp/drawio.zip

EXPOSE 80