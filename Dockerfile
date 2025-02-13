FROM php:8.2-apache-bullseye

ENV MOODLE_VERSION=4.3 \
    MOODLE_DATA=/var/moodledata \
    APACHE_DOCUMENT_ROOT=/var/www/html \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    git \
    unzip \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip intl opcache \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

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

RUN a2enmod rewrite && \
    sed -i 's/^ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf && \
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf

COPY . ${APACHE_DOCUMENT_ROOT}/

RUN chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT} && \
    find ${APACHE_DOCUMENT_ROOT} -type d -exec chmod 755 {} \; && \
    find ${APACHE_DOCUMENT_ROOT} -type f -exec chmod 644 {} \; && \
    mkdir -p ${MOODLE_DATA} && \
    chown -R www-data:www-data ${MOODLE_DATA} && \
    chmod -R 0777 ${MOODLE_DATA} && \
    chmod -R 0755 ${APACHE_DOCUMENT_ROOT}/admin/cli/*

# Fix permission issue
RUN chmod 755 /var/www && \
    chown www-data:www-data /var/www

# Cleanup unnecessary files
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
