# FROM php:8.2-fpm-alpine
# This is the base image. It means our image will start with a minimal Linux distribution (Alpine)
# that already has PHP 8.2 with PHP-FPM installed.
# PHP-FPM (FastCGI Process Manager) is the component that executes PHP code,
# typically used with web servers like Nginx or Apache.
FROM php:8.2-fpm-alpine

# WORKDIR /var/www/html
# Sets the working directory inside the container. All subsequent commands (COPY, RUN, CMD)
# will be executed relative to this directory unless specified otherwise.
# This is where your Laravel project files will reside.
WORKDIR /var/www/html

# RUN apk add --no-cache ...
# apk is the package manager for Alpine Linux.
# add --no-cache ensures that package caches are not stored, keeping the image size small.
# We install system-level dependencies required by Laravel or its extensions:
# - git: Often needed for Composer to download packages from Git repositories.
# - curl: A command-line tool for transferring data, used by various scripts.
# - zip, unzip: For handling compressed files, common for Composer.
# - mysql-client: Command-line client for MySQL, useful for interacting with the DB server
#                 from within the container (e.g., for php artisan migrate).
# - libpng-dev, libjpeg-turbo-dev: Development libraries for image processing.
#   Needed if you enable the 'gd' PHP extension, which is good for basic image handling.
# - nodejs, npm: JavaScript runtime and package manager. Essential if your Laravel app uses
#   frontend build tools like Laravel Mix or Vite (check for package.json in your project).
#   If guestbook_laravel doesn't use them, you can comment out/remove these for a smaller image.
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    mysql-client \
    libpng-dev \
    libjpeg-turbo-dev
    #nodejs \
    #npm

# RUN docker-php-ext-install pdo_mysql gd
# This command compiles and installs specific PHP extensions.
# - pdo_mysql: PHP Data Objects (PDO) extension for MySQL. Absolutely essential for Laravel
#              to connect to a MySQL database.
# - gd: Graphics Draw extension for image manipulation. Useful if you ever need to resize
#       images or create thumbnails within your Laravel app.
RUN docker-php-ext-install pdo_mysql gd

# COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# This is a multi-stage build technique. It takes the composer executable
# from the official Composer Docker image (latest version) and copies it
# into our current image. This ensures we have the latest Composer.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# *** CRITICAL CHANGE HERE: COPY ALL APPLICATION CODE BEFORE COMPOSER INSTALL ***
# This ensures 'artisan' and other project files are present
COPY . .

# COPY composer.json composer.lock ./
# RUN composer install --no-dev --optimize-autoloader --no-interaction
# We copy only composer.json and composer.lock first, then run composer install.
# This optimizes Docker caching: if only your application code changes (but not
# composer.json/lock), Docker can use the cached layer for composer install,
# making subsequent builds faster.
# - --no-dev: Skips installing development dependencies (phpunit, mockery, etc.)
#               which are not needed in production images, saving space.
# - --optimize-autoloader: Optimizes Composer's autoloader for faster class loading.
# - --no-interaction: Prevents Composer from asking for user input.
#COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction

# COPY . .
# Copies all remaining files from your local project directory (the build context)
# into the container's working directory (/var/www/html).
#COPY . .

# COPY .env.example .env
# RUN php artisan key:generate
# These steps set up a basic .env file and generate an app key inside the image.
# For production deployment, you'll typically pass actual environment variables
# during docker run or docker-compose up using -e flags, which will
# override these values. But for a self-contained image that can run for basic testing,
# this is useful.
#COPY .env.example .env
#RUN php artisan key:generate

# RUN npm install
# RUN npm run build
# These commands install Node.js dependencies (from package.json) and then build
# your frontend assets (CSS, JavaScript) using tools like Webpack or Vite.
# If the guestbook_laravel app doesn't have a package.json or uses compiled assets,
# you can comment out or remove these lines. Check your project structure!
# If you later add a frontend framework (Vue/React) or tailwindcss/bootstrap via npm,
# you'll need these.
#RUN npm install
#RUN npm run build

# EXPOSE 9000
# Informs Docker that the container will listen on port 9000 at runtime.
# This is the default port for PHP-FPM. It doesn't actually publish the port
# but serves as documentation.
EXPOSE 9000

# CMD ["php-fpm"]
# The default command that will be executed when a container starts from this image.
# This starts the PHP-FPM service, which will be ready to receive requests from Nginx.
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT}"]
