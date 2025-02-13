# Menggunakan base image PHP Apache yang lebih ringan
FROM php:8.2-apache-bullseye

# Set environment variables
ENV MOODLE_DATA=/var/moodledata \
    APACHE_DOCUMENT_ROOT=/var/www/html \
    DEBIAN_FRONTEND=noninteractive

# Install dependencies secara minimal
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip intl opcache \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Konfigurasi PHP untuk produksi
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'max_execution_time=300'; \
    echo 'memory_limit=256M'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# Konfigurasi Apache
RUN a2enmod rewrite && \
    sed -i 's/^ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf && \
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf

# Salin kode Moodle
COPY . ${APACHE_DOCUMENT_ROOT}/

# Set permissions dengan tepat
RUN chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT} && \
    find ${APACHE_DOCUMENT_ROOT} -type d -exec chmod 755 {} \; && \
    find ${APACHE_DOCUMENT_ROOT} -type f -exec chmod 644 {} \; && \
    mkdir -p ${MOODLE_DATA} && \
    chown -R www-data:www-data ${MOODLE_DATA} && \
    chmod -R 0755 ${MOODLE_DATA}

# Cleanup tambahan
RUN rm -rf ${APACHE_DOCUMENT_ROOT}/.git* \
    ${APACHE_DOCUMENT_ROOT}/.github \
    ${APACHE_DOCUMENT_ROOT}/.travis.yml \
    ${APACHE_DOCUMENT_ROOT}/phpunit* \
    ${APACHE_DOCUMENT_ROOT}/tests \
    ${APACHE_DOCUMENT_ROOT}/vendor/*/tests

EXPOSE 80
CMD ["apache2-foreground"]
