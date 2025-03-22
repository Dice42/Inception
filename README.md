# Inception
# Inception Project - Dockerized LEMP Stack Setup

This README provides comprehensive instructions on how to build and run a LEMP (Linux, Nginx, MariaDB, PHP) stack using Docker. The project includes setting up Docker containers for Nginx, MariaDB, and WordPress (PHP-FPM), orchestrated with Docker Compose. The guide consolidates information from the individual components to help you start the project seamlessly.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Environment Setup](#environment-setup)
- [Building and Running the Project](#building-and-running-the-project)
  - [Using Makefile Commands](#using-makefile-commands)
  - [Manual Docker Compose Commands](#manual-docker-compose-commands)
- [Component Details](#component-details)
  - [MariaDB Service](#mariadb-service)
  - [WordPress Service](#wordpress-service)
  - [Nginx Service](#nginx-service)
- [Accessing the Services](#accessing-the-services)
  - [Accessing the WordPress Site](#accessing-the-wordpress-site)
  - [Testing Nginx and SSL](#testing-nginx-and-ssl)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Prerequisites

- **Docker** and **Docker Compose** installed on your system.
- Basic understanding of **Docker**, **Nginx**, **MariaDB**, and **WordPress**.
- Ensure that the user running Docker commands has the necessary permissions.

## Project Structure

```
.
├── Makefile
├── srcs
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements
│       ├── mariadb
│       │   ├── Dockerfile
│       │   └── tools
│       │       └── entrypoint.sh
│       ├── wordpress
│       │   ├── Dockerfile
│       │   └── tools
│       │       └── entrypoint.sh
│       └── nginx
│           ├── Dockerfile
│           └── tools
│               ├── entrypoint.sh
│               └── nginx.conf
└── README.md
```

## Environment Setup

1. **Clone the Repository**

   Clone the project repository to your local machine:

   ```bash
   git clone https://github.com/yourusername/inception.git
   cd inception
   ```

2. **Set Up Environment Variables**

   The `.env` file contains the necessary environment variables for the services. Ensure it includes the following:

   ```ini
   MARIADB_NAME=dicedb
   MARIADB_USER=dice
   MARIADB_PWD=dice42
   WP_USER=dice
   WP_PASS=Dice@1234
   WP_EMAIL=dice@dice.com
   WP_USER2=lighthouse
   WP_PASS2=Lighthouse42
   WP_EMAIL2=light@house.com
   ```

3. **Create Necessary Directories**

   The project uses bind mounts for data persistence. Create the following directories:

   ```bash
   mkdir -p /home/$(whoami)/data/mariadb
   mkdir -p /home/$(whoami)/data/wordpress
   ```

## Building and Running the Project

### Using Makefile Commands

The project includes a `Makefile` to simplify common tasks.

- **Build and Start Services**

  ```bash
  make up
  ```

  This command will:

  - Create necessary directories.
  - Build Docker images.
  - Start the containers in detached mode.

- **Stop Services**

  ```bash
  make down
  ```

- **Rebuild Services**

  ```bash
  make build
  ```

- **Clean Up**

  ```bash
  make clean
  ```

- **Force Clean (Removes All Docker Data and Volumes)**

  **Warning**: This will remove all Docker images, containers, networks, and volumes.

  ```bash
  make fclean
  ```

- **Rebuild Everything**

  ```bash
  make re
  ```

- **View Logs**

  ```bash
  make logs
  ```

### Manual Docker Compose Commands

Alternatively, you can use Docker Compose commands directly.

- **Build and Start Services**

  ```bash
  cd srcs
  docker-compose up -d --build
  ```

- **Stop Services**

  ```bash
  docker-compose down
  ```

## Component Details

### MariaDB Service

- **Docker Image Location**: `srcs/requirements/mariadb/`
- **Dockerfile**: Builds an Alpine-based MariaDB image.
- **Entrypoint Script**: Initializes the database, creates the specified database and user, and starts the MariaDB daemon.

**Key Points:**

- **Exposed Port**: `3306`
- **Data Persistence**: Uses a bind mount to `/var/lib/mysql` for data storage.

### WordPress Service

- **Docker Image Location**: `srcs/requirements/wordpress/`
- **Dockerfile**: Builds an Alpine-based WordPress image with PHP-FPM.
- **Entrypoint Script**: Downloads and configures WordPress using WP-CLI, connects to the MariaDB database, and starts PHP-FPM.

**Key Points:**

- **Exposed Port**: `9000`
- **Data Persistence**: Uses a bind mount to `/var/www/html` for WordPress files.

### Nginx Service

- **Docker Image Location**: `srcs/requirements/nginx/`
- **Dockerfile**: Builds an Alpine-based Nginx image.
- **Entrypoint Script**: Generates a self-signed SSL certificate if not present and starts Nginx.
- **Configuration**: Custom `nginx.conf` is used to configure Nginx to work with SSL and reverse-proxy to the WordPress service.

**Key Points:**

- **Exposed Port**: `443`
- **SSL Certificate**: Self-signed certificate generated using OpenSSL during container startup.

to check connectivity from ngnix with wordpress:
docker exec nginx apk add curl && docker exec nginx curl -v telnet://wordpress:9000
## Accessing the Services

### Accessing the WordPress Site

- Open your web browser and navigate to `https://localhost`.

- **Note**: Since a self-signed SSL certificate is used, your browser will display a security warning. You can proceed past the warning for testing purposes.

- **Login Credentials**:

  - **Admin User**:
    - Username: `dice` (from `WP_USER` in `.env`)
    - Password: `Dice@1234` (from `WP_PASS` in `.env`)

  - **Additional User**:
    - Username: `lighthouse` (from `WP_USER2` in `.env`)
    - Password: `Lighthouse42` (from `WP_PASS2` in `.env`)

### Testing Nginx and SSL

- **Check Nginx Connectivity to WordPress**:

  ```bash
  docker exec nginx apk add curl
  docker exec nginx curl -v telnet://wordpress:9000
  ```

- **Test SSL Certificate**:

  ```bash
  openssl s_client -connect localhost:443 -showcerts
  ```

## Troubleshooting

- **Docker Permission Issues**:

  If you encounter permission issues when running Docker commands, you may need to add your user to the `docker` group:

  ```bash
  sudo usermod -aG docker $(whoami)
  ```

  Then, log out and log back in for the changes to take effect.

- **Ports Already in Use**:

  Ensure that ports `3306`, `9000`, and `443` are not being used by other services on your host machine.

- **Container Logs**:

  Check the logs of individual containers for error messages:

  ```bash
  docker logs mariadb
  docker logs wordpress
  docker logs nginx
  ```

- **Rebuild Images**:

  If you make changes to Dockerfiles or configurations, rebuild the images:

  ```bash
  make build
  ```

- **Access Issues with WordPress**:

  - Ensure the `mariadb` and `wordpress` containers are running and healthy.
  - Verify that the database credentials in `.env` match in both the `mariadb` and `wordpress` services.

- **Browser SSL Warning**:

  - The self-signed SSL certificate will cause a browser warning. You can bypass this warning for testing purposes.
  - For production environments, consider using a trusted SSL certificate from a Certificate Authority.

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MariaDB Official Documentation](https://mariadb.com/kb/en/)
- [WordPress Official Documentation](https://wordpress.org/support/)
- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)

---

By following this guide, you should be able to set up and run the Dockerized LEMP stack successfully. If you encounter any issues, please refer to the [Troubleshooting](#troubleshooting) section or consult the official documentation provided in the [References](#references).

If you have any questions or need further assistance, feel free to reach out.

