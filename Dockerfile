# SnappyMail Docker Container
# Simple, modern & fast web-based email client
# Based on official SnappyMail requirements: https://github.com/the-djmaze/snappymail/wiki/Installation-instructions#requirements
FROM php:8.2-apache

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="SnappyMail webmail client with all required and optional PHP extensions"

# Set environment variables
ENV SNAPPYMAIL_VERSION=2.38.2
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Install system dependencies for SnappyMail
RUN apt-get update && apt-get install -y \
    # Basic utilities
    wget \
    unzip \
    curl \
    # Required libraries
    libxml2-dev \
    zlib1g-dev \
    libzip-dev \
    # Optional but recommended libraries
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libc-client-dev \
    libkrb5-dev \
    libldap2-dev \
    libsasl2-dev \
    libtidy-dev \
    # GnuPG for encrypted emails
    gnupg \
    libgpgme-dev \
    # Clean up cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/

# Install required PHP extensions for SnappyMail
RUN docker-php-ext-install -j$(nproc) \
        # Required extensions
        mbstring \
        xml \
        dom \
        zip \
        # Optional but recommended extensions
        gd \
        iconv \
        intl \
        imap \
        ldap \
        tidy \
        # Performance extensions
        opcache \
        # PDO extensions for contacts
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite

# Install PECL extensions
RUN set -eux; \
    # Install build dependencies
    apt-get update && apt-get install -y \
        autoconf \
        g++ \
        gcc \
        libc6-dev \
        make \
        pkg-config; \
    # Redis for caching
    pecl install redis; \
    docker-php-ext-enable redis; \
    # GnuPG for encrypted emails
    pecl install gnupg; \
    docker-php-ext-enable gnupg; \
    # UUID extension
    pecl install uuid; \
    docker-php-ext-enable uuid; \
    # Cleanup
    docker-php-source delete; \
    apt-get purge -y autoconf g++ gcc libc6-dev make pkg-config; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

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