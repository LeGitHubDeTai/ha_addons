ARG BUILD_FROM
FROM $BUILD_FROM

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

# ===============================
# BASE DEPENDENCIES
# ===============================
RUN apk add --no-cache \
    ca-certificates \
    unzip \
    build-base \
    python3 \
    py3-pip \
    nodejs \
    npm \
    wget \
    bash \
    tzdata \
    su-exec

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /app

RUN wget https://github.com/plankanban/planka/releases/download/v2.1.0/planka-prebuild.zip -O planka.zip && \
    unzip planka.zip && \
    rm planka.zip && \
    cp -r planka-2.1.0/* ./ && \
    rm -rf planka-2.1.0

# IMPORTANT: npm install DOIT créer le venv
RUN node --version && npm --version && npm install

# ===============================
# START SCRIPT
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 1337

CMD ["/run.sh"]

