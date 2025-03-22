# README for MariaDB Installation

This README provides detailed instructions on how to build and run a MariaDB container using Docker. It includes steps to set up the Docker image, configure the MariaDB service, and examples of usage.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Installation Steps](#installation-steps)
  - [1. Build the Docker Image](#1-build-the-docker-image)
  - [2. Run the MariaDB Container](#2-run-the-mariadb-container)
- [Configuration Details](#configuration-details)
  - [Dockerfile Explanation](#dockerfile-explanation)
  - [Entrypoint Script Explanation](#entrypoint-script-explanation)
- [Usage](#usage)
- [Environment Variables](#environment-variables)
- [Common Issues](#common-issues)
- [References](#references)

## Prerequisites

- **Docker** installed on your system.
- Basic understanding of **Docker** and **MariaDB**.
- Required environment variables set in a `.env` file or passed during runtime.

## Directory Structure

```
.
├── Dockerfile
└── tools
    └── entrypoint.sh
```

## Installation Steps

### 1. Build the Docker Image

Navigate to the directory containing the `Dockerfile` and build the Docker image:

```bash
docker build -t my_mariadb_image .
```

### 2. Run the MariaDB Container

Run the container with the necessary environment variables:

```bash
docker run -d \
  --name my_mariadb_container \
  -p 3306:3306 \
  --env MARIADB_NAME=<database_name> \
  --env MARIADB_USER=<username> \
  --env MARIADB_PWD=<password> \
  my_mariadb_image
```

Replace `<database_name>`, `<username>`, and `<password>` with your desired database name, username, and password.

## Configuration Details

### Dockerfile Explanation

The `Dockerfile` sets up an Alpine-based MariaDB image.

```1:15:srcs/requirements/mariadb/Dockerfile
FROM alpine:3.20

RUN apk update && apk add --no-cache mariadb mariadb-client openrc

EXPOSE 3306

RUN openrc

RUN touch /run/openrc/softlevel

COPY ./tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

**Key Points:**

- **Base Image**: Uses Alpine Linux 3.20 for a lightweight image.
- **Packages Installed**:
  - `mariadb`: The MariaDB server.
  - `mariadb-client`: The MariaDB client tools.
  - `openrc`: For managing services.
- **Exposed Port**: 3306, the default MariaDB port.
- **OpenRC Setup**: Initializes OpenRC to manage the MariaDB service.
- **Entrypoint Script**: Copies and sets execution permissions for the `entrypoint.sh` script.

### Entrypoint Script Explanation

The `entrypoint.sh` script sets up and starts the MariaDB service.

```1:22:srcs/requirements/mariadb/tools/entrypoint.sh
#!/bin/sh

/etc/init.d/mariadb setup

rc-service mariadb start

echo "CREATE DATABASE IF NOT EXISTS $MARIADB_NAME;" > md.file
echo "CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PWD' ;" >> md.file
echo "GRANT ALL PRIVILEGES ON $MARIADB_NAME.* TO '$MARIADB_USER'@'%' ;" >> md.file
echo "FLUSH PRIVILEGES;" >> md.file

mariadb < md.file

sed -i 's/skip-networking/#skip-networking/g' /etc/my.cnf.d/mariadb-server.cnf
sed -i 's/#bind-address=0.0.0.0/bind-address=0.0.0.0/g' /etc/my.cnf.d/mariadb-server.cnf

rc-service mariadb restart
rc-service mariadb stop

/usr/bin/mariadbd --basedir=/usr --datadir=/var/lib/mysql \
--plugin-dir=/usr/lib/mariadb/plugin --user=mysql \
--pid-file=/run/mysqld/mariadb.pid
```

**Key Points:**

- **Initialization**: Sets up the MariaDB data directory.
- **Service Start**: Starts the MariaDB service to perform initial configuration.
- **Database and User Creation**:
  - Creates a database if it doesn't exist.
  - Creates a user with the provided credentials.
  - Grants all privileges to the user on the created database.
- **Configuration Adjustments**:
  - Modifies `mariadb-server.cnf` to comment out `skip-networking`.
  - Ensures `bind-address` is set to `0.0.0.0` for external access.
- **Service Restart**: Restarts and then stops the MariaDB service to apply changes.
- **Manual Daemon Start**: Starts the MariaDB daemon with specific parameters.

## Usage

Once the container is running, you can connect to the MariaDB server using a client:

```bash
mysql -h localhost -P 3306 -u <username> -p
```

Replace `<username>` with the username you set during container run.

## Environment Variables

- `MARIADB_NAME`: The name of the database to create.
- `MARIADB_USER`: The username for the new MariaDB user.
- `MARIADB_PWD`: The password for the new MariaDB user.

These can be set in a `.env` file or passed directly into the container using the `--env` flag.

## Common Issues

- **Permission Denied**:
  - Ensure that the `entrypoint.sh` script has execution permissions.
    ```bash
    chmod +x tools/entrypoint.sh
    ```
- **Port Already in Use**:
  - Make sure port **3306** is free or adjust the port mapping in the `docker run` command.
- **Environment Variables Not Set**:
  - Double-check that all required environment variables are provided and correctly referenced in the scripts.

## References

- [MariaDB Official Documentation](https://mariadb.com/kb/en/)
- [Docker Documentation](https://docs.docker.com/)
- [OpenRC Guide](https://wiki.gentoo.org/wiki/OpenRC)

---

This README should help you set up and run your MariaDB Docker container effectively. If you have any questions or encounter issues, feel free to reach out.
