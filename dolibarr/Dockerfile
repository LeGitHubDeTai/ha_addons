ARG BUILD_FROM
FROM $BUILD_FROM

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"

ENV DOLIBARR_VERSION=22.0.4

# ===============================
# 1️⃣ Dépendances système
# ===============================
RUN apk add --no-cache \
    unzip \
    curl \
    mariadb-client \
    postgresql-client \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    libzip-dev \
    icu-dev \
    pkgconfig \
    apache2 \
    php \
    php-apache2 \
    php-gd \
    php-mysqli \
    php-pdo \
    php-pdo_mysql \
    php-pgsql \
    php-xml \
    php-zip \
    php-intl \
    php-calendar \
    php-soap \
    php-bcmath \
    php-curl

# ===============================
# 2️⃣ Configuration Apache
# ===============================
# Enable rewrite module in Alpine
RUN sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf
RUN rm -f /etc/apache2/httpd.conf
COPY apache.conf /etc/apache2/conf.d/dolibarr.conf

# ===============================
# 3️⃣ Télécharger Dolibarr
# ===============================
RUN curl -L https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.zip -o /tmp/dolibarr.zip \
    && unzip /tmp/dolibarr.zip -d /tmp \
    && mkdir -p /var/www/html \
    && rm -rf /var/www/html/* \
    && cp -r /tmp/dolibarr-${DOLIBARR_VERSION}/htdocs/* /var/www/html/ \
    && rm -rf /tmp/dolibarr*

# ===============================
# 4️⃣ Permissions
# ===============================
# Alpine uses 'apache' user instead of 'www-data'
RUN chown -R apache:apache /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

RUN mkdir -p /data/documents \
    && chown -R apache:apache /data

# ===============================
# 5️⃣ Script de démarrage
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 80
CMD ["/run.sh"]
