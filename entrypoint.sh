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

# Use environment variables
ADMIN_USER="$SNAPPYMAIL_ADMIN_USER"
ADMIN_PASS="$SNAPPYMAIL_ADMIN_PASS"

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
    
    # Create or update config file
    if [ ! -f "$config_file" ]; then
        {
            echo "[security]"
            echo "admin_login = \"$ADMIN_USER\""
            echo "admin_password = \"$password_hash\""
        } > "$config_file"
    else
        # Update existing config
        if grep -q "admin_login" "$config_file"; then
            sed -i "s/admin_login = .*/admin_login = \"$ADMIN_USER\"/" "$config_file"
        else
            echo "admin_login = \"$ADMIN_USER\"" >> "$config_file"
        fi
        
        if grep -q "admin_password" "$config_file"; then
            sed -i "s/admin_password = .*/admin_password = \"$password_hash\"/" "$config_file"
        else
            echo "admin_password = \"$password_hash\"" >> "$config_file"
        fi
    fi
    
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