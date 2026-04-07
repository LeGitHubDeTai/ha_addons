ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive

# ===============================
# BASE DEPENDENCIES
# ===============================
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        build-essential \
        python3 \
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

RUN apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

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
