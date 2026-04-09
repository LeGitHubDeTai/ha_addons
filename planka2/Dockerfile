ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive

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
    && rm -rf /var/cache/apk/*

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
        https://github.com/plankanban/planka/releases/latest/download/planka-prebuild.zip && \
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
