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
    wget \
    bash \
    tzdata \
    su-exec \
    openssl \
    gnupg \
    build-essential \
    python3-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ===============================
# INSTALL NODEJS 22
# ===============================
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /app

RUN wget https://github.com/plankanban/planka/releases/download/v2.1.0/planka-prebuild.zip -O planka.zip && \
    unzip planka.zip && \
    rm planka.zip && \
    cp -r planka/* ./ && \
    rm -rf planka

# IMPORTANT: npm install DOIT créer le venv
RUN node --version && npm --version && npm install

# ===============================
# START SCRIPT
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 1337

CMD ["/run.sh"]

