ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

# Set environment variables
ENV NODE_VERSION=22
ENV PORT=1337

# Install required packages
RUN apk add --no-cache \
    nodejs \
    npm \
    curl \
    supervisor \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Download and extract Planka
RUN wget -O planka.zip https://github.com/plankanban/planka/archive/refs/tags/v2.1.0.zip \
    && unzip planka.zip \
    && rm planka.zip \
    && mv planka-2.1.0/* . \
    && rm -rf planka-2.1.0 \
    && chown -R root:root /app

# Install dependencies
RUN npm install

# Create data directories
RUN mkdir -p /data/user-avatars /data/project-background-images /data/attachments

# Copy run script
COPY run.sh /run.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /etc/supervisord.conf /run.sh

# Set environment variables
ENV NODE_ENV=production
ENV PORT=1337

EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:1337/api/health || exit 1

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
