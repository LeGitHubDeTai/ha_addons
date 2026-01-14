ARG BUILD_FROM
FROM $BUILD_FROM

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

ARG SYNCTHING_VERSION="2.0.13"

RUN set -eux; \
    apk add --no-cache curl ca-certificates; \
    curl -L \
      "https://github.com/syncthing/syncthing/releases/download/v${SYNCTHING_VERSION}/syncthing-linux-amd64-v${SYNCTHING_VERSION}.tar.gz" \
      | tar xz; \
    mv syncthing-linux-amd64-v${SYNCTHING_VERSION}/syncthing /usr/bin/syncthing; \
    chmod +x /usr/bin/syncthing; \
    rm -rf syncthing-linux-amd64-v${SYNCTHING_VERSION}

COPY root /
RUN chmod +x /etc/s6-overlay/s6-rc.d/syncthing-setup/run

ENV HOME=/share \
    STCONFDIR=/config \
    STDATADIR=/data \
    STNODEFAULTFOLDER=1 \
    STNORESTART=1 \
    STNOUPGRADE=1

ENTRYPOINT [ "/init" ]
CMD []
