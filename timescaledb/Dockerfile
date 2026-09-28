# TimescaleDB — compilé depuis les sources GitHub officielles (timescale/timescaledb)
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

ARG TIMESCALEDB_VERSION=2.29.2
ARG PG_MAJOR=17

RUN apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        jq \
        postgresql${PG_MAJOR} \
        postgresql${PG_MAJOR}-client \
        su-exec \
        tzdata \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        cmake \
        coreutils \
        dpkg \
        dpkg-dev \
        git \
        icu-dev \
        linux-headers \
        openssl-dev \
        postgresql${PG_MAJOR}-dev \
        util-linux-dev \
    && pg_versions set-default "${PG_MAJOR}" \
    && git clone --depth 1 --branch "${TIMESCALEDB_VERSION}" \
        https://github.com/timescale/timescaledb.git /usr/src/timescaledb \
    && cd /usr/src/timescaledb \
    && ./bootstrap \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DREGRESS_CHECKS=OFF \
        -DTAP_CHECKS=OFF \
        -DGENERATE_DOWNGRADE_SCRIPT=OFF \
        -DWARNINGS_AS_ERRORS=OFF \
    && make -C build -j"$(nproc)" install \
    && test -f "$(pg_config --sharedir)/extension/timescaledb.control" \
    && cd / \
    && rm -rf /usr/src/timescaledb \
    && apk del .build-deps

COPY root /
RUN chmod +x /etc/s6-overlay/s6-rc.d/timescaledb/run

EXPOSE 5432

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD pg_isready -h /run/postgresql -U postgres -d postgres || exit 1

ENTRYPOINT ["/init"]
