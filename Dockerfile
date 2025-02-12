# Use an official PHP image as a base
FROM php:7.4-fpm

# Set the working directory to /app
WORKDIR /app

# Copy the Moodle code into the container
COPY . /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    libapache2-mod-php7.4 \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-zip \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN sed -i 's/;date.timezone =/date.timezone = Asia/Jakarta/' /etc/php/7.4/fpm/php.ini
RUN sed -i 's/;memory_limit =/memory_limit = 512M/' /etc/php/7.4/fpm/php.ini
RUN sed -i 's/;post_max_size =/post_max_size = 128M/' /etc/php/7.4/fpm/php.ini
RUN sed -i 's/;upload_max_filesize =/upload_max_filesize = 128M/' /etc/php/7.4/fpm/php.ini

# Expose the port that Apache will use
EXPOSE 80

# Run Apache
CMD ["apache2-foreground"]
