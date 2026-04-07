ARG BUILD_FROM
FROM ${BUILD_FROM}

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
    python3-dev \
    py3-pip \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /app

RUN curl -fsSL -o planka.zip \
        https://github.com/plankanban/planka/releases/latest/download/planka-prebuild.zip && \
    unzip planka.zip && \
    mv planka/* . && \
    rmdir planka && \
    rm planka.zip

# IMPORTANT: npm install DOIT créer le venv
RUN npm install

# ===============================
# START SCRIPT
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
