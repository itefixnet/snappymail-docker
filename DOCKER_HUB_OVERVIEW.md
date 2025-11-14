# SnappyMail Docker Image

A simple, modern & fast web-based email client in a Docker container.

## Quick Start

```bash
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

Access SnappyMail at `http://localhost:8080`

## Environment Variables

### Required Variables
- `SNAPPYMAIL_ADMIN_USER` - Admin username
- `SNAPPYMAIL_ADMIN_PASS` - Admin password  
- `TZ` - Timezone (e.g., `America/New_York`, `Europe/London`, `UTC`)

### Optional Variables
- `SNAPPYMAIL_MAX_ATTACHMENT_SIZE` - Maximum attachment size (default: 50M)

## Volumes

- `/var/www/html/data` - SnappyMail data directory (configurations, logs, cache)

## Ports

- `80` - HTTP port

## Email Server Configuration

Configure your email server settings in the admin panel at `http://localhost:8080/?admin`:

- **IMAP**: Port 993 with SSL/TLS encryption
- **SMTP**: Port 587 with STARTTLS encryption

## Timezone Reference

Common timezone examples:
- `America/New_York` - Eastern Time (US)
- `Europe/London` - GMT/BST (UK)
- `Europe/Paris` - Central European Time  
- `Asia/Tokyo` - Japan Standard Time
- `Australia/Sydney` - Australian Eastern Time
- `UTC` - Coordinated Universal Time

For more timezones, see: [Wikipedia Time Zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

## System Requirements

- **Memory**: 128MB RAM recommended
- **Storage**: ~40MB for application, additional space for email data

## Tags

- `latest` - Latest stable version
- `2.38.2` - Specific version
- `2.38.1` - Previous version

## Links

- **SnappyMail**: https://snappymail.eu/
- **GitHub**: https://github.com/the-djmaze/snappymail
- **Docker Repository**: https://github.com/itefixnet/snappymail-docker
- **Issues**: https://github.com/itefixnet/snappymail-docker/issues

## License

This Docker image configuration is provided as-is. SnappyMail itself is licensed under GNU AGPL v3.