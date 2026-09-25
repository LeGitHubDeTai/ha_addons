ARG BUILD_FROM
FROM ${BUILD_FROM}

# Les ARG déclarés avant FROM doivent être re-déclarés après pour rester en portée
ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Version upstream slskd — mise à jour par le workflow auto-upgrade-soulseek
ARG SLSKD_VERSION=0.26.0

RUN set -eux; \
    apk add --no-cache \
        ca-certificates \
        curl \
        jq \
        unzip \
        icu-libs \
        libgcc \
        libstdc++ \
        libintl \
        krb5-libs \
        zlib \
        openssl; \
    case "${BUILD_ARCH}" in \
        "amd64") SLSKD_RUNTIME="linux-musl-x64" ;; \
        "aarch64") SLSKD_RUNTIME="linux-musl-arm64" ;; \
        *) echo "Unsupported architecture: ${BUILD_ARCH}"; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/slskd/slskd/releases/download/${SLSKD_VERSION}/slskd-${SLSKD_VERSION}-${SLSKD_RUNTIME}.zip" -o /tmp/slskd.zip; \
    mkdir -p /opt/slskd; \
    unzip -o /tmp/slskd.zip -d /opt/slskd; \
    chmod +x /opt/slskd/slskd; \
    rm -f /tmp/slskd.zip; \
    /opt/slskd/slskd --version || true; \
    mkdir -p /data /share/soulseek/downloads /share/soulseek/incomplete /share/soulseek/share

COPY root /
RUN chmod +x /etc/s6-overlay/s6-rc.d/soulseek/run

EXPOSE 5030 5031 50300

ENTRYPOINT [ "/init" ]
CMD []
