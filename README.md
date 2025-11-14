# SnappyMail Docker Container

A Docker container for [SnappyMail](https://snappymail.eu/) - a simple, modern & fast web-based email client.

SnappyMail is a drastically upgraded & secured fork of RainLoop Webmail Community edition, providing a lightweight, fast, and secure webmail interface.

## Features

- **PHP 8.2** with Apache web server
- **All required PHP extensions** for SnappyMail functionality
- **Optimized configuration** for performance and security
- **Volume support** for persistent data storage
- **Health checks** included
- **Simple Docker run setup** - no compose required

## Quick Start

### Using the Startup Script (Recommended)

1. Clone this repository:
```bash
git clone <repository-url>
cd snappymail-docker
```

2. Run the startup script:
```bash
./start.sh
```

3. Access SnappyMail at `http://localhost:8080`

### Manual Docker Run

```bash
# Build the image
docker build -t snappymail .

# Run the container
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  --restart unless-stopped \
  snappymail
```

## Initial Setup

1. **Access the Admin Interface**: Navigate to `http://localhost:8080/?admin`

2. **First Login**: 
   - Username: `admin`
   - Password: Check the container logs or the file `/var/www/html/data/_data_/_default_/admin_password.txt`
   
   ```bash
   # Get the admin password
   docker exec snappymail cat /var/www/html/data/_data_/_default_/admin_password.txt
   ```

3. **Configure Mail Server**: Set up your IMAP/SMTP server settings in the admin panel

4. **Security**: Change the default admin password immediately after first login

## Configuration

### Environment Variables

- `TZ`: Set timezone (default: UTC)

### Volumes

- `/var/www/html/data`: SnappyMail data directory (configurations, logs, cache)

### Ports

- `80`: HTTP port (mapped to `8080` in docker-compose)

## Email Server Configuration

SnappyMail supports various email providers. Configure your email settings in the admin panel:

### Common IMAP/SMTP Settings

**Gmail:**
- IMAP: `imap.gmail.com:993` (SSL)
- SMTP: `smtp.gmail.com:587` (STARTTLS)

**Outlook/Hotmail:**
- IMAP: `outlook.office365.com:993` (SSL)
- SMTP: `smtp-mail.outlook.com:587` (STARTTLS)

**Yahoo:**
- IMAP: `imap.mail.yahoo.com:993` (SSL)
- SMTP: `smtp.mail.yahoo.com:587` (STARTTLS)

## Security Considerations

1. **Use HTTPS**: Always use HTTPS in production (consider a reverse proxy like Traefik or nginx)
2. **Secure Data Directory**: The `data` directory contains sensitive information
3. **Regular Updates**: Keep the container updated with the latest SnappyMail version
4. **Firewall**: Restrict access to the admin panel (`/?admin`)

## Advanced Configuration

### Using with Reverse Proxy

Example with nginx or Traefik - add labels when running the container:

```bash
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  --restart unless-stopped \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.snappymail.rule=Host(\`mail.example.com\`)" \
  --label "traefik.http.routers.snappymail.tls=true" \
  snappymail
```

### Custom PHP Configuration

To modify PHP settings, mount a custom configuration file:

```bash
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  -v $(pwd)/custom-php.ini:/usr/local/etc/php/conf.d/custom.ini \
  --restart unless-stopped \
  snappymail
```

### Backup

To backup your SnappyMail data:

```bash
docker run --rm \
  -v snappymail_data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/snappymail-backup-$(date +%Y%m%d).tar.gz -C /data .
```

## System Requirements

- **PHP Extensions**: mbstring, zip, json, xml, dom, gd, iconv, intl, tidy, opcache
- **Memory**: Minimum 256MB RAM (recommended 512MB+)
- **Storage**: 100MB+ for application, additional space for email data

## Troubleshooting

### Check Logs

```bash
# Container logs
docker logs snappymail

# Follow logs in real-time
docker logs -f snappymail

# Apache logs
docker exec snappymail tail -f /var/log/apache2/error.log
```

### Permission Issues

```bash
# Fix permissions if needed
docker exec snappymail chown -R www-data:www-data /var/www/html
```

### Admin Password Reset

If you lose the admin password:

```bash
# Remove the admin password file to generate a new one
docker exec snappymail rm -f /var/www/html/data/_data_/_default_/admin_password.txt
# Restart container
docker restart snappymail
# Check new password
docker exec snappymail cat /var/www/html/data/_data_/_default_/admin_password.txt
```

## Updates

To update to a newer version of SnappyMail:

1. Update the `SNAPPYMAIL_VERSION` in the Dockerfile
2. Rebuild and restart the container:
   ```bash
   # Stop current container
   docker stop snappymail
   docker rm snappymail
   
   # Rebuild and start
   docker build -t snappymail .
   docker run -d \
     --name snappymail \
     -p 8080:80 \
     -v snappymail_data:/var/www/html/data \
     --restart unless-stopped \
     snappymail
   ```

Or use the Makefile:
```bash
make update
```

## Contributing

Feel free to contribute improvements, bug fixes, or feature requests.

## License

This Docker configuration is provided as-is. SnappyMail itself is licensed under GNU AGPL v3.

## Links

- [SnappyMail Official Website](https://snappymail.eu/)
- [SnappyMail GitHub Repository](https://github.com/the-djmaze/snappymail)
- [SnappyMail Documentation](https://github.com/the-djmaze/snappymail/wiki)
