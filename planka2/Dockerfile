ARG BUILD_FROM
FROM ${BUILD_FROM}

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
    python3-dev \
    py3-pip \
    nodejs \
    npm \
    supervisor \
    openssl \
    nginx \
    && rm -rf /var/cache/apk/*

# ===============================
# INSTALL PLANKA
# ===============================
WORKDIR /app

RUN curl -fsSL -o planka.zip \
        https://github.com/plankanban/planka/releases/download/$PLANKA_VERSION/planka-prebuild.zip && \
    unzip planka.zip && \
    cp -r planka/. . && \
    rm -rf planka && \
    rm planka.zip

# IMPORTANT: npm install DOIT créer le venv
RUN npm install

# ===============================
# START SCRIPT
# ===============================
# Create log directories
RUN mkdir -p /var/log/supervisor /var/log/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
