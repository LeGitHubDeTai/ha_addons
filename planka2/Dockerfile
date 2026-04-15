ARG BUILD_FROM=ghcr.io/hassio-addons/base:20.0.4

FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive

# ===============================
# BASE DEPENDENCIES
# ===============================
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        wget \
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

# RUN curl -fsSL -o planka.zip \
#         https://github.com/plankanban/planka/releases/latest/download/planka-prebuild.zip && \
#     unzip planka.zip && \
#     rm planka.zip

# ===============================
# DOWNLOAD PLANKA PREBUILD
# ===============================
ARG PLANKA_VERSION="v2.0.0"
RUN wget -O planka.zip "https://github.com/plankanban/planka/releases/download/${PLANKA_VERSION}/planka-prebuild.zip" && \
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

EXPOSE 1337

CMD ["/run.sh"]
