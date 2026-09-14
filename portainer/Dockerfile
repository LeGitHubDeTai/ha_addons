ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

USER root

RUN chmod +x /entrypoint.sh

COPY run.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]