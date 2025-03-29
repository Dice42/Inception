# Nginx Service Documentation

This document explains the Nginx service implementation for the Inception project, focusing on HTTPS configuration and WordPress integration.

## Service Overview

This Nginx service is configured to:
- Serve as a secure HTTPS web server (port 443)
- Act as a reverse proxy for WordPress
- Use TLS 1.2/1.3 with self-signed certificates
- Handle PHP processing through FastCGI

## Implementation Details

### 1. Dockerfile Breakdown
```dockerfile
FROM alpine:3.20

RUN apk update && apk add --no-cache nginx openssl

COPY tools/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 443

CMD [ "/entrypoint.sh" ]
```

**What each command does:**
- `FROM alpine:3.20`: Uses Alpine Linux for a minimal image size
- `RUN apk update && apk add`: Installs Nginx and OpenSSL
- `COPY` commands: Add our custom configuration and startup script
- `EXPOSE 443`: Documents that the container uses HTTPS port
- `CMD`: Runs our entrypoint script on container start

### 2. SSL Certificate Generation
The `entrypoint.sh` script handles SSL certificate creation:

```bash
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

**OpenSSL command breakdown:**
- `-x509`: Creates a self-signed certificate
- `-nodes`: No password protection for the private key
- `-subj`: Sets the domain name
- `-addext`: Adds Subject Alternative Name for modern browser compatibility
- `-days 365`: Certificate validity period
- `-newkey rsa:2048`: Creates a new 2048-bit RSA key pair

### 3. Nginx Configuration
Key sections of `nginx.conf`:

```nginx
server {
    # SSL Configuration
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/self-signed.crt;
    ssl_certificate_key /etc/self-signed.key;

    # WordPress Configuration
    root /var/www/html/wordpress;
    index index.php index.html;

    # PHP Processing
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Configuration explained:**
1. **SSL Settings**:
   - Enables HTTPS on port 443
   - Uses modern TLS protocols only
   - Specifies certificate locations

2. **WordPress Integration**:
   - Sets document root to WordPress directory
   - Configures index files priority

3. **PHP Handling**:
   - Routes PHP requests to WordPress container
   - Uses FastCGI protocol on port 9000
   - Sets correct script path for PHP processing

## Usage

### Building the Container
```bash
docker build -t nginx-service .
```

### Running the Container
```bash
docker run -d \
  --name nginx \
  -p 443:443 \
  -v wordpress_data:/var/www/html/wordpress \
  nginx-service
```

### Verifying the Setup
1. Check if Nginx is running:
   ```bash
   docker ps | grep nginx
   ```

2. Test SSL configuration:
   ```bash
   curl -k https://mohammoh.42.fr
   ```

## Security Considerations
- Using TLS 1.2/1.3 only (no older protocols)
- Self-signed certificate for development
- No HTTP (port 80) access, HTTPS only
- FastCGI connection to WordPress container only
