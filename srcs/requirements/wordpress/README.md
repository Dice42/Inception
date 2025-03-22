# WordPress Docker Container Setup

This README provides detailed instructions on how to build and run a WordPress container using Docker. It includes steps to set up the Docker image, configure the WordPress service, and examples of usage.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Installation Steps](#installation-steps)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Build the Docker Image](#2-build-the-docker-image)
  - [3. Run the WordPress Container](#3-run-the-wordpress-container)
- [Configuration Details](#configuration-details)
  - [Dockerfile Breakdown](#dockerfile-breakdown)
  - [Entrypoint Script Breakdown](#entrypoint-script-breakdown)
- [Usage Examples](#usage-examples)
  - [Accessing the WordPress Site](#accessing-the-wordpress-site)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Prerequisites

- **Docker** installed on your system. You can download it from the [official Docker website](https://www.docker.com/get-started).
- Basic understanding of **Docker** and **WordPress**.
- Required files are placed in the correct directories as per the [Directory Structure](#directory-structure).
- A running **MariaDB** container that the WordPress container can connect to. Ensure the MariaDB container is configured appropriately.

## Directory Structure

Your project should have the following structure:

```
.
├── Dockerfile
└── tools
    └── entrypoint.sh
```

- **Dockerfile**: Contains instructions to build the WordPress Docker image.
- **tools/entrypoint.sh**: A script executed when the container starts to set up WordPress.

## Installation Steps

### 1. Clone the Repository

Clone the project repository or create a new directory with the necessary files:

```bash
git clone https://github.com/yourusername/your-wordpress-project.git
cd your-wordpress-project
```

### 2. Build the Docker Image

Build the Docker image using the provided `Dockerfile`:

```bash
docker build -t my_wordpress_image .
```

- `-t my_wordpress_image`: Tags the image with a name for easier reference.
- `.`: Specifies that the build context is the current directory.

### 3. Run the WordPress Container

Run the Docker container with the necessary environment variables:

```bash
docker run -d \
  --name my_wordpress_container \
  -p 9000:9000 \
  --env MARIADB_NAME=<database_name> \
  --env MARIADB_USER=<db_username> \
  --env MARIADB_PWD=<db_password> \
  --env WP_USER=<admin_username> \
  --env WP_PASS=<admin_password> \
  --env WP_EMAIL=<admin_email> \
  --env WP_USER2=<subscriber_username> \
  --env WP_PASS2=<subscriber_password> \
  --env WP_EMAIL2=<subscriber_email> \
  my_wordpress_image
```

Replace:

- `<database_name>`: The name of the database to connect to.
- `<db_username>`: The username for the MariaDB database.
- `<db_password>`: The password for the MariaDB database.
- `<admin_username>`: The WordPress admin username.
- `<admin_password>`: The WordPress admin password.
- `<admin_email>`: The WordPress admin email.
- `<subscriber_username>`: The WordPress subscriber username.
- `<subscriber_password>`: The WordPress subscriber password.
- `<subscriber_email>`: The WordPress subscriber email.

**Note**: Ensure that the WordPress container can connect to the MariaDB container, possibly by using a Docker network or linking the containers.

---

## Configuration Details

### Dockerfile Breakdown

Below is the `Dockerfile` used to build the WordPress image:

```1:11:srcs/requirements/wordpress/Dockerfile
FROM alpine:3.20

RUN apk update && apk add php php83 php83-fpm php83-mysqli php83-mbstring php83-gd php83-opcache php83-phar php83-xml mariadb-client wget tar

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

**Explanation:**

- **Base Image**: Uses Alpine Linux 3.20 for a lightweight image.
- **Packages Installed**:
  - `php`, `php83`, `php83-fpm`, `php83-mysqli`, `php83-mbstring`, `php83-gd`, `php83-opcache`, `php83-phar`, `php83-xml`: PHP and required extensions for WordPress.
  - `mariadb-client`: MariaDB client for database connectivity.
  - `wget`, `tar`: Utilities used in the entrypoint script.
- **Copy Entrypoint Script**:
  - Copies the `entrypoint.sh` script into the container at `/usr/local/bin/entrypoint.sh`.
- **Set Permissions**:
  - Grants execute permissions to the `entrypoint.sh` script.
- **Expose Port**:
  - Exposes port `9000` for PHP-FPM to listen on.
- **Entrypoint**:
  - Specifies the `entrypoint.sh` script to run when the container starts.

### Entrypoint Script Breakdown

The `entrypoint.sh` script sets up and starts WordPress when the container runs.

```1:39:srcs/requirements/wordpress/tools/entrypoint.sh
#!/bin/sh

# Download WP-CLI
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Create WordPress directory and navigate to it
mkdir -p /var/www/html/wordpress
cd /var/www/html/wordpress

# Download WordPress core files
php -d memory_limit=512M /usr/local/bin/wp --allow-root core download --force

# Set permissions
chmod 777 -R /var/www/html/wordpress

# Configure wp-config.php
mv wp-config-sample.php wp-config.php

sed -i "s/'database_name_here'/'$MARIADB_NAME'/g" wp-config.php
sed -i "s/'username_here'/'$MARIADB_USER'/g" wp-config.php
sed -i "s/'password_here'/'$MARIADB_PWD'/g" wp-config.php
sed -i "s/'localhost'/'mariadb'/g" wp-config.php

# Configure PHP-FPM to listen on all interfaces
sed -i "s|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|g" /etc/php83/php-fpm.d/www.conf

# Set listen owner and group
echo 'listen.owner = nobody' >> /etc/php83/php-fpm.d/www.conf
echo 'listen.group = nobody' >> /etc/php83/php-fpm.d/www.conf

# Install WordPress
wp --allow-root --path=/var/www/html/wordpress core install \
    --url='http://localhost' --title='WordPress' \
    --skip-email --admin_email="$WP_EMAIL" \
    --admin_user="$WP_USER" \
    --admin_password="$WP_PASS"

# Create an additional WordPress user
wp --allow-root --path=/var/www/html/wordpress user create \
    $WP_USER2 $WP_EMAIL2 --role=subscriber \
    --user_pass="$WP_PASS2"

# Start PHP-FPM if wp-config.php exists
if [ -f /var/www/html/wordpress/wp-config.php ]; then
    php-fpm83 --nodaemonize
fi
```

**Explanation:**

- **Download WP-CLI**: Downloads the WordPress Command Line Interface (WP-CLI) tool for automating WordPress tasks.
- **Set Up WordPress Directory**: Creates the WordPress directory and navigates into it.
- **Download WordPress Core**: Uses WP-CLI to download the WordPress core files.
- **Set Permissions**: Changes permissions to allow read/write/execute for all users (*Note: Setting permissions to `777` is not recommended for production environments due to security risks*).
- **Configure `wp-config.php`**:
  - Renames `wp-config-sample.php` to `wp-config.php`.
  - Uses `sed` to replace placeholder values with environment variables for database configuration.
  - Changes the database host to `mariadb` (ensure the MariaDB service is reachable with this hostname).
- **Configure PHP-FPM**:
  - Modifies the PHP-FPM configuration to listen on all interfaces (`0.0.0.0`) on port `9000`.
  - Sets the `listen.owner` and `listen.group` to `nobody`.
- **Install WordPress**:
  - Uses WP-CLI to install WordPress with the provided site information and admin credentials.
- **Create Additional User**:
  - Creates an additional WordPress user with the role of `subscriber`.
- **Start PHP-FPM**:
  - Checks if `wp-config.php` exists and starts PHP-FPM in the foreground.

---

## Usage Examples

### Accessing the WordPress Site

Once the container is running and properly connected to a MariaDB database, you can access the WordPress site:

- **Through Nginx or Apache**:
  - If you're using a web server container (e.g., Nginx) that communicates with the WordPress container, navigate to your server's domain or IP address in a web browser.
  - Ensure that your web server is configured to forward PHP requests to the WordPress container on port `9000`.
- **Directly**:
  - Since PHP-FPM listens on port `9000`, it doesn't serve HTTP traffic directly. You need a web server to handle HTTP requests and communicate with PHP-FPM.
  - Alternatively, for testing purposes, you can use tools like PHP's built-in web server.

---

## Environment Variables

The container uses the following environment variables:

- **MariaDB Configuration**:
  - `MARIADB_NAME`: The name of the MariaDB database to connect to.
  - `MARIADB_USER`: The MariaDB username.
  - `MARIADB_PWD`: The MariaDB user password.
- **WordPress Configuration**:
  - `WP_USER`: The WordPress admin username.
  - `WP_PASS`: The WordPress admin password.
  - `WP_EMAIL`: The WordPress admin email.
  - `WP_USER2`: The secondary WordPress user's username.
  - `WP_PASS2`: The secondary WordPress user's password.
  - `WP_EMAIL2`: The secondary WordPress user's email.

These can be set in a `.env` file or passed directly into the container using the `--env` flag.

### Example `.env` File

Create a `.env` file in the project directory:

```
MARIADB_NAME=wordpress_db
MARIADB_USER=db_user
MARIADB_PWD=db_password
WP_USER=admin
WP_PASS=admin_password
WP_EMAIL=admin@example.com
WP_USER2=user
WP_PASS2=user_password
WP_EMAIL2=user@example.com
```

Then, run the container using:

```bash
docker run -d \
  --name my_wordpress_container \
  -p 9000:9000 \
  --env-file .env \
  my_wordpress_image
```

---

## Troubleshooting

### Cannot Connect to Database

- **Issue**: WordPress cannot connect to the MariaDB database.
- **Solution**:
  - Ensure the MariaDB container is running and accessible.
  - Verify that the database credentials and host (`mariadb`) are correct.
  - Ensure both containers are on the same Docker network.
    ```bash
    docker network ls
    ```
  - Connect the containers to the same network:
    ```bash
    docker network create wordpress_network
    docker network connect wordpress_network my_mariadb_container
    docker network connect wordpress_network my_wordpress_container
    ```

### PHP-FPM Fails to Start

- **Issue**: The container exits because PHP-FPM cannot start.
- **Solution**:
  - Check the logs of the container for specific error messages:
    ```bash
    docker logs my_wordpress_container
    ```
  - Ensure that the PHP-FPM configuration in `/etc/php83/php-fpm.d/www.conf` is correct.

### Permissions Issues

- **Issue**: Permission denied errors when accessing WordPress files.
- **Solution**:
  - Ensure that the permissions set with `chmod` are appropriate.
  - For security, consider setting more restrictive permissions like `755` for directories and `644` for files.

### WordPress Site Not Accessible

- **Issue**: Unable to access the WordPress site in a browser.
- **Solution**:
  - Ensure that your web server (e.g., Nginx or Apache) is properly configured to proxy requests to the WordPress container on port `9000`.
  - Check that the WordPress container is running:
    ```bash
    docker ps
    ```
  - Verify network settings and port mappings.

---

## References

- [WordPress Official Documentation](https://wordpress.org/support/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [Docker Documentation](https://docs.docker.com/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/)

---

By following this guide, you should be able to build and run a WordPress Docker container, configure the service, and serve your WordPress site.

If you have any questions or need further assistance, please feel free to reach out or consult the references provided.
