#!/bin/sh

# Ensure storage and cache directories are writable by the web server
# This is crucial for Laravel applications
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Run Laravel migrations (optional, but often needed)
# php artisan migrate --force

# Start PHP-FPM in the background
php-fpm &

# Start Nginx in the foreground
nginx -g "daemon off;"
