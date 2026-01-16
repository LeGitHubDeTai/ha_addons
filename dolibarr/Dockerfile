FROM php:8.2-apache-bullseye

ENV DOLIBARR_VERSION=22.0.4

# ===============================
# 1️⃣ Dépendances système
# ===============================
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    mariadb-client \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# ===============================
# 2️⃣ Extensions PHP
# ===============================

# GD
RUN docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install imap

# Bases de données
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    pgsql \
    pdo_pgsql

# Extensions Dolibarr
RUN docker-php-ext-install \
    xml \
    zip \
    intl \
    calendar \
    soap \
    bcmath

# ===============================
# 3️⃣ Apache
# ===============================
RUN a2enmod rewrite
RUN rm -f /etc/apache2/sites-enabled/000-default.conf
COPY apache.conf /etc/apache2/sites-enabled/000-dolibarr.conf

# ===============================
# 4️⃣ Télécharger Dolibarr
# ===============================
RUN curl -L https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.zip -o /tmp/dolibarr.zip \
    && unzip /tmp/dolibarr.zip -d /tmp \
    && rm -rf /var/www/html/* \
    && mv /tmp/dolibarr-${DOLIBARR_VERSION}/* /var/www/html/ \
    && rm -rf /tmp/dolibarr*

# ===============================
# 5️⃣ Permissions
# ===============================
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

RUN mkdir -p /data/documents \
    && chown -R www-data:www-data /data

# ===============================
# 6️⃣ Script de démarrage
# ===============================
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 80
CMD ["/run.sh"]
