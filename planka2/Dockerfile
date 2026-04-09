ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

ENV DEBIAN_FRONTEND=noninteractive
ENV PLANKA_VERSION="v2.1.0"

# ===============================
# BASE DEPENDENCIES (Alpine)
# ===============================
RUN apk add --no-cache \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        build-base \
        python3 \
        py3-pip \
        openssl \
        nginx \
    && rm -rf /var/cache/apk/*

# ===============================
# INSTALL SUPERVISORD
# ===============================
RUN pip3 install --break-system-packages supervisor && \
    which supervisord

# ===============================
# INSTALL NODEJS 22
# ===============================
RUN apk add --no-cache \
        nodejs \
        npm

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /opt

RUN curl -fsSL -o planka.zip \
    https://github.com/plankanban/planka/archive/refs/tags/$PLANKA_VERSION.zip && \
    unzip planka.zip && \
    mv planka-2.1.0 planka && \
    rm planka.zip

WORKDIR /opt/planka

# IMPORTANT: npm install DOIT créer le venv
RUN npm install

# ===============================
# START SCRIPT
# ===============================
COPY run.sh /run.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /run.sh

# Create log directories
RUN mkdir -p /var/log/supervisor /var/run

# Verify supervisord installation
RUN which supervisord && ls -la $(which supervisord)

ENTRYPOINT ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
