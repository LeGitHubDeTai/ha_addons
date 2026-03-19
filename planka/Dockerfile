ARG BUILD_FROM
FROM $BUILD_FROM

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
    py3-pip

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /app

RUN mkdir -p /etc/apt/keyrings

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get install nodejs -y

RUN curl -fsSL -o planka.zip \
        https://github.com/plankanban/planka/releases/download/v2.0.3/planka-prebuild.zip && \
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

