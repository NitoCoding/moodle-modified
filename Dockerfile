# Gunakan image PHP dengan Apache sebagai base image
FROM php:8.2-apache

# Set environment variables untuk Moodle
ENV MOODLE_VERSION 3.11
ENV MOODLE_DATA /var/moodledata

# Install dependensi yang diperlukan
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    default-mysql-client \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) intl

# Aktifkan mod rewrite Apache
RUN a2enmod rewrite

# Salin kode Moodle yang sudah dimodifikasi ke dalam container
COPY . /var/www/html/

# Set permissions untuk direktori Moodle
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Buat direktori untuk data Moodle
RUN mkdir -p $MOODLE_DATA \
    && chown -R www-data:www-data $MOODLE_DATA \
    && chmod -R 777 $MOODLE_DATA

# Expose port 80 untuk Apache
EXPOSE 80

# Perintah untuk menjalankan Apache saat container dijalankan
CMD ["apache2-foreground"]
