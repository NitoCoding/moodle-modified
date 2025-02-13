FROM php:8.2-apache-bullseye

ENV MOODLE_DATA=/var/moodledata \
    APACHE_DOCUMENT_ROOT=/var/www/html \
    DEBIAN_FRONTEND=noninteractive

# Install dependencies dengan MySQLi dan ekstensi wajib Moodle
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    git \
    unzip \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        zip \
        intl \
        opcache \
        soap \
        xsl \
        xmlrpc \
        curl \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Konfigurasi PHP untuk Moodle
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'max_execution_time=300'; \
    echo 'memory_limit=256M'; \
    echo 'mysqli.allow_persistent=On'; \
    echo 'mysqli.max_persistent=-1'; \
    echo 'mysqli.max_links=-1'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# Konfigurasi Apache
RUN a2enmod rewrite && \
    sed -i 's/^ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf && \
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf

COPY . ${APACHE_DOCUMENT_ROOT}/

# Set permissions dan konfigurasi direktori
RUN chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT} && \
    find ${APACHE_DOCUMENT_ROOT} -type d -exec chmod 755 {} \; && \
    find ${APACHE_DOCUMENT_ROOT} -type f -exec chmod 644 {} \; && \
    mkdir -p ${MOODLE_DATA} && \
    chown -R www-data:www-data ${MOODLE_DATA} && \
    chmod -R 0777 ${MOODLE_DATA} && \
    chmod -R 0755 ${APACHE_DOCUMENT_ROOT}/admin/cli/* && \
    chmod 755 /var/www && \
    chown www-data:www-data /var/www

# Cleanup
RUN rm -rf \
    ${APACHE_DOCUMENT_ROOT}/.git* \
    ${APACHE_DOCUMENT_ROOT}/.github \
    ${APACHE_DOCUMENT_ROOT}/.travis.yml \
    ${APACHE_DOCUMENT_ROOT}/phpunit* \
    ${APACHE_DOCUMENT_ROOT}/tests \
    ${APACHE_DOCUMENT_ROOT}/vendor/*/tests \
    ${APACHE_DOCUMENT_ROOT}/node_modules

EXPOSE 80
CMD ["apache2-foreground"]
