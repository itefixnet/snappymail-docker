# SnappyMail Docker Container

A Docker container for [SnappyMail](https://snappymail.eu/) - a simple, modern & fast web-based email client.

SnappyMail is a drastically upgraded & secured fork of RainLoop Webmail Community edition, providing a lightweight, fast, and secure webmail interface.

## Features

- **PHP 8.2** with Apache web server
- **All required PHP extensions** for SnappyMail functionality
- **Optimized configuration** for performance and security
- **Volume support** for persistent data storage
- **Health checks** included
- **Simple Docker setup**

## Quick Start

### Option 1: Use Prebuilt Image (Recommended)

Prebuilt Docker images are available at [Docker Hub](https://hub.docker.com/r/itefixnet/snappymail).

```bash
# Run with prebuilt image
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  -e SNAPPYMAIL_ADMIN_USER=myadmin \
  -e SNAPPYMAIL_ADMIN_PASS=mypassword \
  -e TZ=America/New_York \
  --restart unless-stopped \
  itefixnet/snappymail:latest
```

### Option 2: Build from Source

1. Clone this repository:
```bash
git clone <repository-url>
cd snappymail-docker
```

2. Build and run the container:
```bash
# Build the image (uses default version 2.38.2)
docker build -t snappymail .

# Or build with a specific SnappyMail version
docker build --build-arg SNAPPYMAIL_VERSION=2.38.1 -t snappymail .

# Run the container (admin credentials and timezone are REQUIRED)
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  -e SNAPPYMAIL_ADMIN_USER=myadmin \
  -e SNAPPYMAIL_ADMIN_PASS=mypassword \
  -e TZ=Europe/Oslo \
  --restart unless-stopped \
  snappymail
```

3. Access SnappyMail at `http://localhost:8080`

## Initial Setup

1. **Access the Admin Interface**: Navigate to `http://localhost:8080/?admin`

2. **First Login**: 
   - Use the admin credentials you set via the `SNAPPYMAIL_ADMIN_USER` and `SNAPPYMAIL_ADMIN_PASS` environment variables

3. **Configure Mail Server**: Set up your IMAP/SMTP server settings in the admin panel

4. **Security**: Change the default admin password immediately after first login

## Configuration

### Environment Variables

#### Required Variables
- `SNAPPYMAIL_ADMIN_USER`: Admin username (**REQUIRED**)
- `SNAPPYMAIL_ADMIN_PASS`: Admin password (**REQUIRED**)
- `TZ`: Timezone (**REQUIRED**) - See [TIMEZONES.md](TIMEZONES.md) or [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

#### Optional Variables
- `SNAPPYMAIL_MAX_ATTACHMENT_SIZE`: Maximum attachment size (default: 50M)

### Volumes

- `/var/www/html/data`: SnappyMail data directory (configurations, logs, cache)

### Ports

- `80`: HTTP port (mapped to `8080` in the run command)

## Email Server Configuration

Configure your email server settings in the admin panel at `http://localhost:8080/?admin`:

### Standard IMAP/SMTP Ports

- **IMAP**: Port `993` with SSL/TLS encryption
- **SMTP**: Port `587` with STARTTLS encryption

Most modern email providers use these standard ports and encryption methods.

## Security Considerations

1. **Use HTTPS**: Always use HTTPS in production (consider a reverse proxy like Traefik or nginx)
2. **Secure Data Directory**: The `data` directory contains sensitive information
3. **Regular Updates**: Keep the container updated with the latest SnappyMail version
4. **Firewall**: Restrict access to the admin panel (`/?admin`)

## Build Configuration

### Build Arguments

- `SNAPPYMAIL_VERSION`: SnappyMail version to download (default: 2.38.2)

```bash
# Build with default version
docker build -t snappymail .

# Build with specific version
docker build --build-arg SNAPPYMAIL_VERSION=2.38.1 -t snappymail .

# Build with latest version (check GitHub releases)
docker build --build-arg SNAPPYMAIL_VERSION=2.39.0 -t snappymail .
```

**Note**: Check [SnappyMail releases](https://github.com/the-djmaze/snappymail/releases) for available versions.

## Advanced Configuration

### Configuration Examples

All required variables must be provided:

```bash
# Basic setup with required variables
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  -e SNAPPYMAIL_ADMIN_USER=myusername \
  -e SNAPPYMAIL_ADMIN_PASS=mypassword \
  -e TZ=Europe/London \
  --restart unless-stopped \
  snappymail

# With custom attachment size
docker run -d \
  --name snappymail \
  -p 8080:80 \
  -v snappymail_data:/var/www/html/data \
  -e SNAPPYMAIL_ADMIN_USER=myusername \
  -e SNAPPYMAIL_ADMIN_PASS=mypassword \
  -e TZ=Asia/Tokyo \
  -e SNAPPYMAIL_MAX_ATTACHMENT_SIZE=100M \
  --restart unless-stopped \
  snappymail
```

#### Timezone Reference
For a complete list of timezone identifiers, see:
- **[TIMEZONES.md](TIMEZONES.md)** - Common timezones included in this repository  
- **[Wikipedia List](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)** - Complete timezone database
- **[IANA Time Zone Database](https://www.iana.org/time-zones)** - Official timezone database

Common examples: `America/New_York`, `Europe/London`, `Asia/Tokyo`, `UTC`

**Note**: The container will not start without `SNAPPYMAIL_ADMIN_USER`, `SNAPPYMAIL_ADMIN_PASS`, and `TZ` environment variables.

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

- **PHP Extensions**: mbstring (included in this Docker image)
- **Memory**: 128MB RAM recommended
- **Storage**: ~40MB for application, additional space for email data

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

## Docker Hub

Prebuilt images are available at: **[hub.docker.com/r/itefixnet/snappymail](https://hub.docker.com/r/itefixnet/snappymail)**

For Docker Hub documentation, see: **[DOCKER_HUB_OVERVIEW.md](DOCKER_HUB_OVERVIEW.md)**

## Contributing

Feel free to contribute improvements, bug fixes, or feature requests.

## License

This Docker configuration is provided as-is. SnappyMail itself is licensed under GNU AGPL v3.

## Links

- [SnappyMail Official Website](https://snappymail.eu/)
- [SnappyMail GitHub Repository](https://github.com/the-djmaze/snappymail)
- [SnappyMail Documentation](https://github.com/the-djmaze/snappymail/wiki)
- [Docker Hub Repository](https://hub.docker.com/r/itefixnet/snappymail)
