# MariaDB Docker Service Documentation

This document explains the MariaDB Docker service setup for the Inception project.

## Docker Image Details

### Base Image
- Uses `alpine:3.20` for a lightweight container base
- Alpine Linux provides a minimal but complete environment

### Installed Packages
- `mariadb`: Main database server
- `mariadb-client`: Command-line tools for MariaDB
- `openrc`: Service manager for Alpine Linux

## Dockerfile Explanation

```dockerfile
FROM alpine:3.20

RUN apk update && apk add --no-cache mariadb mariadb-client openrc

RUN openrc
RUN touch /run/openrc/softlevel

COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

### Key Components:
1. **OpenRC Setup**: Initializes OpenRC and creates required system files
2. **Entrypoint Script**: Copies and makes executable the initialization script

## Entrypoint Script Details

The `entrypoint.sh` script handles the database initialization and configuration:

```bash
#!/bin/sh

# Initialize MariaDB
/etc/init.d/mariadb setup
rc-service mariadb start

# Create database and user
echo "CREATE DATABASE IF NOT EXISTS $MARIADB_NAME;" > md.file
echo "CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PWD' ;" >> md.file
echo "GRANT ALL PRIVILEGES ON $MARIADB_NAME.* TO '$MARIADB_USER'@'%' ;" >> md.file
echo "FLUSH PRIVILEGES;" >> md.file

mariadb < md.file

# Configure network access
sed -i 's/skip-networking/#skip-networking/g' /etc/my.cnf.d/mariadb-server.cnf
sed -i 's/#bind-address=0.0.0.0/bind-address=0.0.0.0/g' /etc/my.cnf.d/mariadb-server.cnf

# Restart and run MariaDB daemon
rc-service mariadb restart
rc-service mariadb stop

/usr/bin/mariadbd --basedir=/usr --datadir=/var/lib/mysql \
  --plugin-dir=/usr/lib/mariadb/plugin --user=mysql \
  --pid-file=/run/mysqld/mariadb.pid
```

## Entrypoint Script Detailed Explanation

The `entrypoint.sh` script initializes and configures the MariaDB server. Let's break down each section:

### 1. Initial Setup
```bash
/etc/init.d/mariadb setup
rc-service mariadb start
```
- `/etc/init.d/mariadb setup`: Creates the initial MariaDB system tables and data directory
- `rc-service mariadb start`: Starts the MariaDB service using OpenRC init system

### 2. Database and User Configuration
```bash
echo "CREATE DATABASE IF NOT EXISTS $MARIADB_NAME;" > md.file
echo "CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PWD' ;" >> md.file
echo "GRANT ALL PRIVILEGES ON $MARIADB_NAME.* TO '$MARIADB_USER'@'%' ;" >> md.file
echo "FLUSH PRIVILEGES;" >> md.file

mariadb < md.file
```
- Creates a temporary SQL file (`md.file`) with necessary database commands
- `CREATE DATABASE`: Creates a new database if it doesn't exist
- `CREATE USER`: Creates a new user with:
  - Username from `$MARIADB_USER`
  - Password from `$MARIADB_PWD`
  - `@'%'` allows connections from any host
- `GRANT ALL PRIVILEGES`: Gives the user full access to the database
- `FLUSH PRIVILEGES`: Reloads the grant tables to apply changes
- `mariadb < md.file`: Executes the SQL commands from the file

### 3. Network Configuration
```bash
sed -i 's/skip-networking/#skip-networking/g' /etc/my.cnf.d/mariadb-server.cnf
sed -i 's/#bind-address=0.0.0.0/bind-address=0.0.0.0/g' /etc/my.cnf.d/mariadb-server.cnf
```
- First `sed`: Comments out `skip-networking` to allow network connections
- Second `sed`: Sets `bind-address` to `0.0.0.0` to accept connections from any IP
- These changes are made in the MariaDB server configuration file

### 4. Service Management
```bash
rc-service mariadb restart
rc-service mariadb stop
```
- `restart`: Restarts the service to apply configuration changes
- `stop`: Stops the service to prepare for manual daemon start

### 5. Manual Daemon Start
```bash
/usr/bin/mariadbd --basedir=/usr --datadir=/var/lib/mysql \
  --plugin-dir=/usr/lib/mariadb/plugin --user=mysql \
  --pid-file=/run/mysqld/mariadb.pid
```
Starts MariaDB daemon with specific parameters:
- `--basedir=/usr`: Base installation directory
- `--datadir=/var/lib/mysql`: Location of database files
- `--plugin-dir=/usr/lib/mariadb/plugin`: Directory containing MariaDB plugins
- `--user=mysql`: Run as mysql system user
- `--pid-file=/run/mysqld/mariadb.pid`: Location of process ID file

This manual start ensures proper configuration and allows for custom runtime parameters.

### Script Functions:
1. **Database Setup**: Initializes MariaDB system tables
2. **User Configuration**: Creates database and user with privileges
3. **Network Configuration**: Enables remote connections
4. **Service Management**: Manages MariaDB service using OpenRC
5. **Daemon Start**: Runs MariaDB with specific configurations

## Environment Variables

Required environment variables:
- `MARIADB_NAME`: Database name to create
- `MARIADB_USER`: Username for database access
- `MARIADB_PWD`: Password for the database user

## Build and Run Commands

### Building the Image
```bash
docker build -t mariadb-service ./srcs/requirements/mariadb
```

### Running the Container
```bash
docker run -d \
  --name mariadb \
  -e MARIADB_NAME=mydb \
  -e MARIADB_USER=myuser \
  -e MARIADB_PWD=mypassword \
  -p 3306:3306 \
  mariadb-service
```

## Testing the Connection

To test the MariaDB connection:
```bash
mysql -h localhost -P 3306 -u $MARIADB_USER -p
```

## Security Notes

- Always use strong passwords for database users
- Avoid exposing port 3306 to public networks
- Store sensitive environment variables in secure configuration files
