ARG BUILD_FROM
FROM ${BUILD_FROM}

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
    bash \
    bash-completion \
    shadow \
    sudo \
    ruby \
    ruby-bundler \
    ruby-dev \
    build-base \
    sqlite-dev \
    libffi-dev \
    tzdata

# ===============================
# INSTALL FIZZY
# ===============================
RUN mkdir -p /opt/fizzy

# Copy the startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Create a user for running the application
RUN groupadd -g 1000 fizzy && \
    useradd -u 1000 -g fizzy -m -s /bin/bash fizzy

# Set proper permissions
RUN chmod -R 755 /opt/fizzy && \
    chown -R fizzy:fizzy /opt/fizzy

EXPOSE 80

CMD ["/run.sh"]