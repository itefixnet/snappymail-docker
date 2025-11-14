# Basic SnappyMail Docker Container
# Simple, modern & fast web-based email client
FROM php:8.2-apache

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="SnappyMail webmail client - Simple, modern & fast web-based email client"

# Set environment variables
ENV SNAPPYMAIL_VERSION=2.38.2
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Install system dependencies and PHP extensions required by SnappyMail
RUN apt-get update && apt-get install -y \
    # Basic utilities
    wget \
    unzip \
    curl \
    # Required libraries for PHP extensions
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libicu-dev \
    libc-client-dev \
    libkrb5-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    # Optional: GnuPG for encrypted emails
    gnupg \
    # Optional: Tidy for HTML cleanup
    libtidy-dev \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        # Required extensions
        mbstring \
        zip \
        json \
        xml \
        dom \
        # Recommended extensions
        gd \
        iconv \
        intl \
        tidy \
        # Optional for better performance
        opcache

# Install additional PECL extensions
RUN pecl install redis \
    && docker-php-ext-enable redis

# Configure Apache
RUN a2enmod rewrite \
    && a2enmod ssl \
    && a2enmod headers

# Set proper document root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Download and install SnappyMail
WORKDIR /tmp
RUN wget -O snappymail.tar.gz "https://github.com/the-djmaze/snappymail/releases/download/v${SNAPPYMAIL_VERSION}/snappymail-${SNAPPYMAIL_VERSION}.tar.gz" \
    && tar -xzf snappymail.tar.gz -C ${APACHE_DOCUMENT_ROOT} --strip-components=0 \
    && rm snappymail.tar.gz

# Copy custom entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Set proper permissions
RUN chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT} \
    && find ${APACHE_DOCUMENT_ROOT} -type d -exec chmod 755 {} \; \
    && find ${APACHE_DOCUMENT_ROOT} -type f -exec chmod 644 {} \; \
    && chmod -R 777 ${APACHE_DOCUMENT_ROOT}/data \
    && chmod +x /usr/local/bin/entrypoint.sh

# Create a custom PHP configuration
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'upload_max_filesize = 50M'; \
    echo 'post_max_size = 50M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_vars = 3000'; \
    echo 'date.timezone = UTC'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.max_accelerated_files = 4000'; \
    echo 'opcache.revalidate_freq = 2'; \
} > /usr/local/etc/php/conf.d/snappymail.ini

# Create a simple Apache configuration for SnappyMail
RUN { \
    echo '<VirtualHost *:80>'; \
    echo '    DocumentRoot /var/www/html'; \
    echo '    <Directory /var/www/html>'; \
    echo '        Options -Indexes +FollowSymLinks'; \
    echo '        AllowOverride All'; \
    echo '        Require all granted'; \
    echo '    </Directory>'; \
    echo '    <Directory /var/www/html/data>'; \
    echo '        Deny from all'; \
    echo '    </Directory>'; \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log'; \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined'; \
    echo '</VirtualHost>'; \
} > /etc/apache2/sites-available/000-default.conf

# Create data volume
VOLUME ["/var/www/html/data"]

# Expose port 80
EXPOSE 80

# Environment variables for admin customization (REQUIRED)
# ENV SNAPPYMAIL_ADMIN_USER=your_admin_username
# ENV SNAPPYMAIL_ADMIN_PASS=your_admin_password

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]