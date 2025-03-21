FROM php:8.0-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    php8-bcmath \
    curl \
    git \
    unzip \
    bash

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql bcmath

# Copy crontab file
COPY docker-compose/crontab /etc/crontabs/root

CMD ["crond", "-f"]
