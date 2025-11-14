FROM php:8.2-apache

# Build argument for SnappyMail version
ARG SNAPPYMAIL_VERSION=2.38.2

RUN apt-get update && apt-get install -y wget

# Download and extract SnappyMail
WORKDIR /var/www/html
RUN wget -O snappymail.tar.gz "https://github.com/the-djmaze/snappymail/releases/download/v${SNAPPYMAIL_VERSION}/snappymail-${SNAPPYMAIL_VERSION}.tar.gz" \
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
