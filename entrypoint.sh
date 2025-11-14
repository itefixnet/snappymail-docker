#!/bin/bash

# SnappyMail entrypoint script
# Handles admin account customization via environment variables

set -e

# Check required environment variables
if [ -z "$SNAPPYMAIL_ADMIN_USER" ]; then
    echo "ERROR: SNAPPYMAIL_ADMIN_USER environment variable is required"
    exit 1
fi

if [ -z "$SNAPPYMAIL_ADMIN_PASS" ]; then
    echo "ERROR: SNAPPYMAIL_ADMIN_PASS environment variable is required"
    exit 1
fi

if [ -z "$TZ" ]; then
    echo "ERROR: TZ (timezone) environment variable is required"
    echo "See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    exit 1
fi

# Use environment variables
ADMIN_USER="$SNAPPYMAIL_ADMIN_USER"
ADMIN_PASS="$SNAPPYMAIL_ADMIN_PASS"
MAX_ATTACHMENT_SIZE="${SNAPPYMAIL_MAX_ATTACHMENT_SIZE:-50M}"

# Set timezone
echo "Setting timezone to: $TZ"
echo "$TZ" > /etc/timezone
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

# Configure PHP with timezone and attachment size
echo "Configuring PHP settings..."
{
    echo "date.timezone = $TZ"
    echo "upload_max_filesize = $MAX_ATTACHMENT_SIZE"
    echo "post_max_size = $MAX_ATTACHMENT_SIZE"
    echo "memory_limit = 128M"
    echo "max_execution_time = 300"
} > /usr/local/etc/php/conf.d/snappymail.ini

# Function to configure admin account
configure_admin() {
    local config_dir="/var/www/html/data/_data_/_default_/configs"
    local config_file="$config_dir/application.ini"
    
    # Wait for SnappyMail to initialize
    sleep 5
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    
    echo "Setting admin username: $ADMIN_USER"
    echo "Setting admin password"
    
    # Create password hash (SnappyMail uses password_hash with default settings)
    local password_hash
    password_hash=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_DEFAULT);")
    
    # Always create a fresh config file to avoid sed issues with special characters
    {
        echo "[security]"
        echo "admin_login = \"$ADMIN_USER\""
        echo "admin_password = \"$password_hash\""
    } > "$config_file"
    
    chown www-data:www-data "$config_file"
    chmod 644 "$config_file"
    
    # Remove any auto-generated password file
    rm -f "/var/www/html/data/_data_/_default_/admin_password.txt"
}

# Apply admin configuration in background after Apache starts
(
    configure_admin
    echo "Admin configuration applied"
) &

# Start Apache in foreground
exec apache2-foreground