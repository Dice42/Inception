# WordPress Service Documentation

This document explains the WordPress service implementation for the Inception project, focusing on PHP-FPM configuration and WordPress setup.

## Service Overview

This WordPress service is configured to:
- Run WordPress with PHP-FPM 8.3
- Connect to a MariaDB database
- Create admin and subscriber users automatically
- Listen on port 9000 for FastCGI connections

## Implementation Details

### 1. Dockerfile Breakdown
```dockerfile
FROM alpine:3.20

RUN apk update && apk add php php83 php83-fpm php83-mysqli php83-mbstring \
    php83-gd php83-opcache php83-phar php83-xml mariadb-client wget tar

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

**What each command does:**
- `FROM alpine:3.20`: Uses Alpine Linux for a minimal image size
- `RUN apk update && apk add`: Installs:
  - PHP 8.3 with FPM for processing PHP
  - Required PHP extensions for WordPress
  - MariaDB client for database connection
  - wget and tar for downloading WordPress
- `EXPOSE 9000`: Documents that PHP-FPM listens on port 9000
- `ENTRYPOINT`: Runs our setup script

### 2. WordPress Setup Script
The `entrypoint.sh` script handles WordPress installation and configuration:

```bash
#!/bin/sh

# Install WP-CLI
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Setup WordPress
mkdir -p /var/www/html/wordpress
cd /var/www/html/wordpress
php -d memory_limit=512M /usr/local/bin/wp --allow-root core download --force

# Configure WordPress
mv wp-config-sample.php wp-config.php
sed -i "s/'database_name_here'/'$MARIADB_NAME'/g" wp-config.php
sed -i "s/'username_here'/'$MARIADB_USER'/g" wp-config.php
sed -i "s/'password_here'/'$MARIADB_PWD'/g" wp-config.php
sed -i "s/'localhost'/'mariadb'/g" wp-config.php

# Configure PHP-FPM
sed -i "s|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|g" /etc/php83/php-fpm.d/www.conf
echo 'listen.owner = nobody' >> /etc/php83/php-fpm.d/www.conf
echo 'listen.group = nobody' >> /etc/php83/php-fpm.d/www.conf

# Install WordPress and create users
wp --allow-root --path=/var/www/html/wordpress core install \
    --url='http://localhost' --title='WordPress' \
    --skip-email --admin_email="$WP_EMAIL" \
    --admin_user="$WP_USER" \
    --admin_password="$WP_PASS"

wp --allow-root --path=/var/www/html/wordpress user create \
    $WP_USER2 $WP_EMAIL2 --role=subscriber \
    --user_pass="$WP_PASS2"

# Start PHP-FPM
if [ -f /var/www/html/wordpress/wp-config.php ]; then
    php-fpm83 --nodaemonize
fi
```

**Script breakdown:**
1. **WP-CLI Installation**: Downloads and installs WordPress CLI tool
2. **WordPress Setup**: Downloads core files and sets permissions
3. **Configuration**: 
   - Updates database connection details
   - Configures PHP-FPM to listen on all interfaces
4. **User Creation**:
   - Creates admin user with full privileges
   - Creates additional subscriber user
5. **Service Start**: Runs PHP-FPM in foreground mode

### 3. Required Environment Variables

```bash
# Database Configuration
MARIADB_NAME=<database_name>
MARIADB_USER=<database_user>
MARIADB_PWD=<database_password>

# WordPress Users
WP_USER=<admin_username>
WP_PASS=<admin_password>
WP_EMAIL=<admin_email>
WP_USER2=<subscriber_username>
WP_PASS2=<subscriber_password>
WP_EMAIL2=<subscriber_email>
```

## Usage

### Building the Container
```bash
docker build -t wordpress-service .
```

### Running the Container
```bash
docker run -d \
  --name wordpress \
  -p 9000:9000 \
  -v wordpress_data:/var/www/html/wordpress \
  --env-file .env \
  wordpress-service
```

### Verifying the Setup
1. Check if WordPress files exist:
   ```bash
   docker exec wordpress ls -la /var/www/html/wordpress
   ```

2. Verify PHP-FPM is running:
   ```bash
   docker exec wordpress ps aux | grep php-fpm
   ```

## Integration with Nginx

This WordPress container is designed to work with Nginx:
- PHP-FPM listens on port 9000
- Nginx forwards PHP requests to this container
- WordPress files are shared through a volume

## Security Notes
- PHP-FPM runs as nobody user
- WordPress core files are downloaded directly from WordPress.org
- Database credentials are passed via environment variables
- TLS termination is handled by Nginx
