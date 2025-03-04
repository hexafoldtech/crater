# Use official PHP 8.2 FPM image
FROM php:8.2-fpm

# Define build arguments
ARG user=appuser
ARG uid=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    nginx \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libmagickwand-dev \
    mariadb-client \
    supervisor

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install and enable Imagick extension
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

RUN apt-get update && apt-get install -y gettext


# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u ${uid} -d /home/${user} ${user} \
    && mkdir -p /home/${user}/.composer \
    && chown -R ${user}:${user} /home/${user}

# Set working directory
WORKDIR /var/www

# Set permissions for storage and cache directories
RUN mkdir -p storage/framework storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chmod -R 775 storage/framework \
    && chown -R www-data:www-data storage bootstrap/cache 

# Copy Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf


# Expose port 8080 for Heroku
EXPOSE 8080

# Start Supervisor as the main process
CMD ["sh", "-c", "envsubst '$$PORT' < /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.tmp && mv /etc/nginx/nginx.conf.tmp /etc/nginx/nginx.conf && supervisord -c /etc/supervisor/conf.d/supervisord.conf"]


