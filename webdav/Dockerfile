ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

ARG WEBDAV_VERSION=5.15.1

RUN set -eux; \
    apk add --no-cache ca-certificates jq openssl wget tar; \
    case "${BUILD_ARCH}" in \
        "amd64") WEBDAV_GOARCH="amd64" ;; \
        "aarch64") WEBDAV_GOARCH="arm64" ;; \
        "armv7") WEBDAV_GOARCH="armv7" ;; \
        "armhf") WEBDAV_GOARCH="armv6" ;; \
        "i386") WEBDAV_GOARCH="386" ;; \
        *) echo "Unsupported architecture: ${BUILD_ARCH}"; exit 1 ;; \
    esac; \
    wget -q "https://github.com/hacdias/webdav/releases/download/v${WEBDAV_VERSION}/linux-${WEBDAV_GOARCH}-webdav.tar.gz" -O /tmp/webdav.tar.gz; \
    tar xzf /tmp/webdav.tar.gz -C /tmp; \
    mv /tmp/webdav /usr/local/bin/webdav; \
    chmod +x /usr/local/bin/webdav; \
    rm -f /tmp/webdav.tar.gz; \
    /usr/local/bin/webdav version

COPY root /
RUN chmod +x /etc/s6-overlay/s6-rc.d/webdav/run

ENTRYPOINT [ "/init" ]
CMD []
