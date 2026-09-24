# Fizzy est déjà installé dans l'image officielle (build-time).
# Cet addon se contente d'ajouter : lecture des options HA, persistance /data et démarrage.
ARG BUILD_FROM=ghcr.io/basecamp/fizzy:main
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG BUILD_VERSION

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

USER root

# jq : lecture de /data/options.json | openssl : génération du SECRET_KEY_BASE
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq openssl \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY run.sh /run.sh
# Anti-CRLF (checkout Windows) + executable
RUN sed -i 's/\r$//' /run.sh && chmod +x /run.sh

WORKDIR /rails
EXPOSE 80 443

ENTRYPOINT ["/run.sh"]
