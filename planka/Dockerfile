ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV NODE_MAJOR=22

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
    gnupg \
    unzip \
    build-base \
    python3 \
    py3-pip \
    openssl \
    nodejs \
    npm \
    postgresql \
    su-exec

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /app

RUN wget https://github.com/plankanban/planka/releases/download/v2.0.3/planka-prebuild.zip -O planka.zip && \
    unzip planka.zip && \
    rm planka.zip

WORKDIR /app/planka

# IMPORTANT: npm install DOIT créer le venv
RUN npm install

# ===============================
# START SCRIPT
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]

