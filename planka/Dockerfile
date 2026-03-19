ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

# ===============================
# BASE DEPENDENCIES
# ===============================
RUN apk add --no-cache \
    ca-certificates \
    curl \
    unzip \
    build-base \
    python3 \
    py3-pip \
    nodejs \
    npm

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /opt

RUN curl -fsSL -o planka.zip \
        https://github.com/plankanban/planka/releases/download/v2.0.3/planka-prebuild.zip && \
    unzip planka.zip && \
    rm planka.zip

WORKDIR /opt/planka

# IMPORTANT: npm install DOIT créer le venv
RUN npm install

# ===============================
# START SCRIPT
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
