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

# Mailpit : SMTP local + boîte de réception (zéro config, codes de connexion lisibles en UI)
RUN case "${BUILD_ARCH}" in \
        amd64) MP_ARCH=amd64 ;; \
        aarch64) MP_ARCH=arm64 ;; \
        *) echo "Architecture non supportée: ${BUILD_ARCH}"; exit 1 ;; \
    esac \
    && curl -fsSL -o /tmp/mailpit.tgz "https://github.com/axllent/mailpit/releases/latest/download/mailpit-linux-${MP_ARCH}.tar.gz" \
    && tar -xzf /tmp/mailpit.tgz -C /usr/local/bin mailpit \
    && chmod +x /usr/local/bin/mailpit \
    && rm -f /tmp/mailpit.tgz \
    && /usr/local/bin/mailpit version

COPY run.sh /run.sh
# Anti-CRLF (checkout Windows) + executable
RUN sed -i 's/\r$//' /run.sh && chmod +x /run.sh

# Desactive SMTP-AUTH en mode SMTP local (Mailpit) : production.rb force "plain" par defaut
COPY local-smtp.rb /rails/config/initializers/zz_fizzy_local_smtp.rb
RUN sed -i 's/\r$//' /rails/config/initializers/zz_fizzy_local_smtp.rb

WORKDIR /rails
EXPOSE 80 443 8025

ENTRYPOINT ["/run.sh"]
