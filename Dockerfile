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
    supervisor \
    gettext

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install and enable Imagick extension
RUN pecl install imagick && docker-php-ext-enable imagick

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN id "$user" &>/dev/null || useradd -G www-data,root -u $uid -d /home/$user $user \
    && mkdir -p /home/${user}/.composer \
    && chown -R ${user}:${user} /home/${user}


# Set working directory
WORKDIR /app

# Copy application files
COPY . .

# 🔹 Ensure `/app/vendor` and Laravel storage directories exist
RUN mkdir -p /app/vendor \
    /app/storage/framework/{sessions,views,cache} \
    /app/storage/logs \
    /app/bootstrap/cache \
 && chmod -R 775 /app/vendor /app/storage /app/bootstrap/cache \
 && chown -R www-data:www-data /app/vendor /app/storage /app/bootstrap/cache

# 🔹 Ensure .env file exists
RUN cp .env.example .env || true

RUN mkdir -p storage/framework storage/framework/sessions storage/framework/views storage/framework/cache storage/logs bootstrap/cache && chmod -R 775 storage bootstrap/cache

# 🔹 Install dependencies as ROOT (to avoid permission issues)
RUN composer install --no-dev --optimize-autoloader

# 🔹 Run Laravel setup commands
RUN php artisan key:generate \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan view:clear \
    && php artisan config:cache

# Copy Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set correct ownership of project before starting
RUN chown -R www-data:www-data /app

# 🔹 Expose Nginx port
EXPOSE 80

# 🔹 Start Nginx and Supervisor
CMD ["sh", "-c", "service nginx start && supervisord -c /etc/supervisor/conf.d/supervisord.conf"]
