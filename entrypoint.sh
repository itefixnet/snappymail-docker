#!/bin/bash

# SnappyMail entrypoint script
# Handles admin account customization via environment variables

set -e

# Default values
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASS=""

# Use environment variables or defaults
ADMIN_USER="${SNAPPYMAIL_ADMIN_USER:-$DEFAULT_ADMIN_USER}"
ADMIN_PASS="${SNAPPYMAIL_ADMIN_PASS:-$DEFAULT_ADMIN_PASS}"

# Function to configure admin account
configure_admin() {
    local config_dir="/var/www/html/data/_data_/_default_/configs"
    local config_file="$config_dir/application.ini"
    
    # Wait for SnappyMail to initialize
    sleep 5
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    
    # If custom admin username is set and it's not the default
    if [ "$ADMIN_USER" != "$DEFAULT_ADMIN_USER" ] && [ -n "$ADMIN_USER" ]; then
        echo "Setting custom admin username: $ADMIN_USER"
        
        # Create or update config file with custom admin user
        if [ ! -f "$config_file" ]; then
            {
                echo "[security]"
                echo "admin_login = \"$ADMIN_USER\""
            } > "$config_file"
        else
            # Update existing config
            if grep -q "admin_login" "$config_file"; then
                sed -i "s/admin_login = .*/admin_login = \"$ADMIN_USER\"/" "$config_file"
            else
                echo "admin_login = \"$ADMIN_USER\"" >> "$config_file"
            fi
        fi
        
        chown www-data:www-data "$config_file"
        chmod 644 "$config_file"
    fi
    
    # If custom admin password is set
    if [ -n "$ADMIN_PASS" ]; then
        echo "Setting custom admin password"
        
        # Create password hash (SnappyMail uses password_hash with default settings)
        local password_hash
        password_hash=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_DEFAULT);")
        
        # Update config with hashed password
        if [ ! -f "$config_file" ]; then
            {
                echo "[security]"
                echo "admin_password = \"$password_hash\""
            } > "$config_file"
        else
            if grep -q "admin_password" "$config_file"; then
                sed -i "s/admin_password = .*/admin_password = \"$password_hash\"/" "$config_file"
            else
                echo "admin_password = \"$password_hash\"" >> "$config_file"
            fi
        fi
        
        chown www-data:www-data "$config_file"
        chmod 644 "$config_file"
        
        # Remove auto-generated password file if it exists
        rm -f "/var/www/html/data/_data_/_default_/admin_password.txt"
    fi
}

# Apply admin configuration in background after Apache starts
(
    configure_admin
    echo "Admin configuration applied"
) &

# Start Apache in foreground
exec apache2-foreground