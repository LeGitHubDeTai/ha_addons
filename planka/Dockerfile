ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH
FROM ${BUILD_FROM}

# Set environment variables
ENV NODE_VERSION=18
ENV PORT=1337

# Install required packages
RUN apk add --no-cache \
    nodejs \
    npm \
    curl \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Download and extract Planka
RUN curl -L -o planka.zip https://github.com/plankanban/planka/releases/download/v2.1.0/planka-prebuild.zip \
    && unzip planka.zip \
    && rm planka.zip \
    && chown -R root:root /app

# Install dependencies
RUN npm install --production

# Create data directories
RUN mkdir -p /data/user-avatars /data/project-background-images /data/attachments

# Copy configuration files
COPY root/ /

# Set permissions
RUN chmod +x /scripts/*.sh

# Expose port
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:1337/api/health || exit 1

# Start the application
CMD ["/scripts/run.sh"]
