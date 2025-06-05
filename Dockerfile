# FROM php:8.2-fpm-alpine
FROM php:8.2-fpm-alpine

# WORKDIR /var/www/html
WORKDIR /var/www/html

# Install system dependencies, including Nginx
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    mysql-client \
    libpng-dev \
    libjpeg-turbo-dev \
    nginx # <--- ADD NGINX HERE

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy all application code
COPY . .

# Run Composer install
RUN composer install --no-dev --optimize-autoloader --no-interaction

# --- NGINX CONFIGURATION ---
# Remove default Nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy your custom Nginx configuration for Laravel
# You'll need to create a `nginx.conf` file in your project root next to your Dockerfile
COPY nginx.conf /etc/nginx/conf.d/default.conf

# --- ENTRYPOINT / CMD CHANGE ---
# Expose the port Nginx will listen on
EXPOSE 8081 

# Use a custom entrypoint script to start both PHP-FPM and Nginx
# Create `docker-entrypoint.sh` in your project root and make it executable
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# This will be the command executed when the container starts
CMD ["docker-entrypoint.sh"]
