FROM php:8.2-apache

# Install packages and PHP extensions
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    gnupg \
    imagemagick \
    libzip-dev \
    libmagickwand-dev \
    libgpgme-dev \
    && docker-php-ext-install mbstring zip \
    && pecl install imagick gnupg \
    && docker-php-ext-enable imagick gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and extract SnappyMail
WORKDIR /var/www/html
RUN wget -O snappymail.tar.gz "https://github.com/the-djmaze/snappymail/releases/download/v2.38.2/snappymail-2.38.2.tar.gz" \
    && tar -xzf snappymail.tar.gz --strip-components=0 \
    && rm snappymail.tar.gz \
    && chown -R www-data:www-data . \
    && chmod -R 755 data

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]