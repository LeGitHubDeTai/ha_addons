FROM nginx:alpine

# Téléchargement de Draw.io version statique
RUN mkdir -p /usr/share/nginx/html && \
    wget https://github.com/jgraph/drawio/archive/refs/tags/v30.0.1.zip -O /tmp/drawio.zip && \
    unzip /tmp/drawio.zip -d /usr/share/nginx/html && \
    rm /tmp/drawio.zip

EXPOSE 80
