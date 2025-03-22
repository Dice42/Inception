# Nginx Docker Container Setup

This README provides detailed instructions on how to build and run an Nginx container using Docker. It includes steps to set up the Docker image, configure the Nginx service, and examples of usage.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Installation Steps](#installation-steps)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Build the Docker Image](#2-build-the-docker-image)
  - [3. Run the Nginx Container](#3-run-the-nginx-container)
- [Configuration Details](#configuration-details)
  - [Dockerfile Breakdown](#dockerfile-breakdown)
  - [Entrypoint Script Breakdown](#entrypoint-script-breakdown)
  - [Nginx Configuration Breakdown](#nginx-configuration-breakdown)
- [Usage Examples](#usage-examples)
  - [Accessing the Nginx Server](#accessing-the-nginx-server)
  - [Testing SSL Certificate](#testing-ssl-certificate)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Prerequisites

- **Docker** installed on your system. You can download it from the [official Docker website](https://www.docker.com/get-started).
- Basic understanding of **Docker** and **Nginx**.
- Required files are placed in the correct directories as per the [Directory Structure](#directory-structure).

## Directory Structure

Your project should have the following structure:

```
.
├── Dockerfile
├── tools
│   ├── entrypoint.sh
│   └── nginx.conf
```

- **Dockerfile**: Contains instructions to build the Nginx Docker image.
- **tools/entrypoint.sh**: A script executed when the container starts to configure Nginx and generate SSL certificates.
- **tools/nginx.conf**: The Nginx configuration file.

## Installation Steps

### 1. Clone the Repository

Clone the project repository or create a new directory with the necessary files:

```bash
git clone https://github.com/yourusername/your-nginx-project.git
cd your-nginx-project
```

### 2. Build the Docker Image

Build the Docker image using the provided `Dockerfile`:

```bash
docker build -t my_nginx_image .
```

- `-t my_nginx_image`: Tags the image with a name for easier reference.
- `.`: Specifies that the build context is the current directory.

### 3. Run the Nginx Container

Run the Docker container:

```bash
docker run -d \
  --name my_nginx_container \
  -p 443:443 \
  my_nginx_image
```

- `-d`: Runs the container in detached mode.
- `--name my_nginx_container`: Assigns a name to the container.
- `-p 443:443`: Maps port 443 of the container to port 443 on the host machine.

---

## Configuration Details

### Dockerfile Breakdown

Below is the `Dockerfile` used to build the Nginx image:

```1:15:srcs/requirements/nginx/Dockerfile
FROM alpine:3.20

RUN apk update && apk add --no-cache nginx openssl

COPY tools/nginx.conf /etc/nginx/nginx.conf

COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 443

CMD [ "/entrypoint.sh" ]
```

**Explanation:**

- **Base Image**: Uses Alpine Linux 3.20 for a lightweight image.
- **Packages Installed**:
  - `nginx`: The Nginx web server.
  - `openssl`: Utility for generating SSL certificates.
- **Copy Configuration Files**:
  - Copies the custom `nginx.conf` to `/etc/nginx/nginx.conf`.
  - Copies the `entrypoint.sh` script to `/entrypoint.sh`.
- **Set Permissions**:
  - Grants execute permissions to the `entrypoint.sh` script.
- **Expose Port**:
  - Exposes port `443` for HTTPS connections.
- **Command**:
  - Specifies the entrypoint script to run when the container starts.

### Entrypoint Script Breakdown

The `entrypoint.sh` script configures SSL and starts the Nginx server.

```1:14:srcs/requirements/nginx/tools/entrypoint.sh
#!/bin/sh

if [ ! -f /etc/self-signed.crt ]; then
    openssl \
        req -x509 \
        -nodes \
        -subj "/CN=mohammoh.42.fr" \
        -addext "subjectAltName=DNS:mohammoh.42.fr" \
        -days 365 \
        -newkey rsa:2048 -keyout /etc/self-signed.key \
        -out /etc/self-signed.crt
fi

nginx -g 'daemon off;'
```

**Explanation:**

- **Shebang**: `#!/bin/sh` indicates the script should be run using the Bourne shell.
- **SSL Certificate Generation**:
  - Checks if `/etc/self-signed.crt` exists. If not, generates a self-signed SSL certificate using `openssl`.
  - The certificate is valid for 365 days and is saved to `/etc/self-signed.crt` and `/etc/self-signed.key`.
- **Starting Nginx**:
  - Runs `nginx -g 'daemon off;'` to start Nginx in the foreground, which is required in Docker containers.

### Nginx Configuration Breakdown

The custom `nginx.conf` file configures the Nginx server.

```1:42:srcs/requirements/nginx/tools/nginx.conf
# /etc/nginx/nginx.conf

user nginx;
worker_processes auto;
pcre_jit on;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate /etc/self-signed.crt;
        ssl_certificate_key /etc/self-signed.key;

        root /var/www/html/wordpress;
        index index.php index.html;

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
}
```

**Explanation:**

- **User and Worker Processes**:
  - Runs Nginx as the `nginx` user.
  - `worker_processes auto;` allows Nginx to automatically adjust the number of worker processes.
- **Error Logging**:
  - Logs errors to `/var/log/nginx/error.log` with the `warn` level.
- **Events**:
  - Sets `worker_connections` to `1024`.
- **HTTP Configuration**:
  - Includes MIME types from the default file.
  - Sets the default content type.
- **Server Configuration**:
  - **SSL Settings**:
    - Listens on port `443` with SSL enabled.
    - Uses TLS protocols `TLSv1.2` and `TLSv1.3`.
    - Specifies the locations of the SSL certificate and key.
  - **Root and Index**:
    - Sets the document root to `/var/www/html/wordpress`.
    - Specifies the default index files.
  - **Location Blocks**:
    - `/`: Handles requests to the root URL.
      - Uses `try_files` to attempt to serve files or route to `index.php`.
    - `~ \.php$`: Handles PHP files.
      - Includes FastCGI parameters.
      - Passes the request to the `wordpress` container on port `9000`.
      - Sets the `SCRIPT_FILENAME` parameter required by PHP.

---

## Usage Examples

### Accessing the Nginx Server

After running the container, you can access the Nginx server in your web browser:

- Open your browser and navigate to `https://localhost`.

**Note**: Since a self-signed SSL certificate is used, your browser will display a security warning. You can safely bypass this for testing purposes.

### Testing SSL Certificate

To view the details of the SSL certificate:

```bash
openssl s_client -connect localhost:443 -showcerts
```

---

## Environment Variables

No specific environment variables are required for this Nginx setup. All configurations are handled within the provided configuration files and scripts.

---

## Troubleshooting

### Browser Warning about SSL Certificate

- **Issue**: Browser shows a warning about the self-signed SSL certificate.
- **Solution**: This is expected for self-signed certificates. You can proceed past the warning for testing purposes. For production, use a certificate from a trusted Certificate Authority (CA) or services like Let's Encrypt.

### Port 443 Already in Use

- **Issue**: The container fails to start because port `443` is already in use.
- **Solution**:
  - Identify the process using the port:
    ```bash
    sudo lsof -i :443
    ```
  - Stop the conflicting service or run the container on a different port by modifying the `-p` flag:
    ```bash
    docker run -d -p <host_port>:443 my_nginx_image
    ```

### Nginx Configuration Errors

- **Issue**: Nginx fails to start due to configuration errors.
- **Solution**:
  - Check the Nginx configuration inside the container:
    ```bash
    docker exec -it my_nginx_container nginx -t
    ```
  - Review error messages and fix configuration issues accordingly.

### Access Denied or 403 Errors

- **Issue**: Receiving access denied or 403 Forbidden errors when accessing the server.
- **Solution**:
  - Ensure that the document root directory `/var/www/html/wordpress` exists and has the correct permissions.
  - If the directory is supposed to be shared with another container (e.g., a WordPress container), ensure that the volume is correctly mounted.

---

## References

- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/)

---

By following this guide, you should be able to build and run an Nginx Docker container, configure the service, and serve content over HTTPS using a self-signed SSL certificate.

If you have any questions or need further assistance, please feel free to reach out or consult the references provided.
