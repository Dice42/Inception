# Inception Project

## Project Overview

This project implements a complete web hosting infrastructure using Docker containers. It demonstrates modern DevOps practices by containerizing and orchestrating a full LEMP (Linux, Nginx, MariaDB, PHP) stack with WordPress.

### Key Features

- **Containerized Services**: Each component runs in its own container
  - Nginx (Web Server with SSL)
  - MariaDB (Database)
  - WordPress (PHP-FPM)
- **Secure Configuration**
  - HTTPS with SSL/TLS
  - Docker secrets for sensitive data
  - Isolated network for containers
- **Data Persistence**
  - Volume mapping for database
  - WordPress files persistence
  - Configuration persistence

## Understanding Docker and Docker Compose

### Docker Basics
Docker enables you to package applications and their dependencies into containers. In this project:
- Each service runs in an isolated container
- Containers are built from Alpine Linux for minimal size
- Services communicate through a Docker network

### Docker Compose
Docker Compose orchestrates multiple containers:
- Defines services in `docker-compose.yml`
- Manages container lifecycle
- Handles networking between services
- Manages volumes and secrets

## Getting Started

### Prerequisites Installation

1. **Virtual Machine Setup**
   - Detailed instructions for VM installation can be found in [INSTALL.md](./install/README.md)
   - Recommended: Debian/Ubuntu based distribution

2. **Docker Installation**
   ```bash
   # Update package index
   sudo apt-get update

   # Install prerequisites
   sudo apt-get install -y \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg \
       lsb-release

   # Add Docker's official GPG key
   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

   # Set up stable repository
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   # Install Docker Engine
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. **Post-Installation Steps**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Log out and back in for changes to take effect
   ```

## Project Structure

```
inception/
├── Makefile                  # Project automation
├── README.md                 # Main documentation
├── INSTALL.md               # Installation guide
└── srcs/
    ├── docker-compose.yml    # Service orchestration
    ├── .env                  # Environment variables
    ├── secrets/              # Docker secrets
    └── requirements/
        ├── mariadb/         # Database service
        │   ├── README.md    # MariaDB documentation
        │   ├── Dockerfile
        │   └── tools/
        ├── wordpress/       # WordPress service
        │   ├── README.md    # WordPress documentation
        │   ├── Dockerfile
        │   └── tools/
        └── nginx/          # Web server service
            ├── README.md    # Nginx documentation
            ├── Dockerfile
            └── tools/
```

## Detailed Service Documentation

Each service has its own detailed README:
- [MariaDB Service Documentation](./srcs/requirements/mariadb/README.md)
- [WordPress Service Documentation](./srcs/requirements/wordpress/README.md)
- [Nginx Service Documentation](./srcs/requirements/nginx/README.md)

## Quick Start

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Set Up Environment**
   ```bash
   # Copy example environment file
   cp srcs/.env.example srcs/.env
   # Edit environment variables as needed
   ```

3. **Start Services**
   ```bash
   make all
   ```

4. **Access WordPress**
   - Open https://localhost in your browser
   - Accept the self-signed certificate warning

## Using the Makefile

### Basic Commands

- **`make all`** (Default Target)
  ```bash
  make all
  ```
  - Creates required directories
  - Starts all containers
  - Shows container logs in follow mode
  
- **`make up`**
  ```bash
  make up
  ```
  - Creates data directories in `/home/$USER/data/`
  - Builds and starts containers in detached mode
  - Equivalent to `docker compose up -d`

- **`make down`**
  ```bash
  make down
  ```
  - Stops and removes all containers
  - Preserves volumes and images
  - Equivalent to `docker compose down`

#### Maintenance Commands

- **`make build`**
  ```bash
  make build
  ```
  - Rebuilds all Docker images from scratch
  - Useful after modifying Dockerfiles or configurations
  - Equivalent to `docker compose build`

- **`make clean`**
  ```bash
  make clean
  ```
  - Stops all containers
  - Removes all Docker images
  - Preserves volumes and data directories

- **`make fclean`** (Full Clean)
  ```bash
  make fclean
  ```
  - Removes all Docker resources:
    - All containers
    - All images
    - All volumes
    - All networks
  - Deletes all data directories
  - **⚠️ Warning**: This will permanently delete all data

#### Utility Commands

- **`make re`**
  ```bash
  make re
  ```
  - Performs a complete rebuild:
    1. Stops and removes containers
    2. Removes images
    3. Rebuilds and starts everything fresh
  - Equivalent to `make clean up`

- **`make logs`**
  ```bash
  make logs
  ```
  - Shows real-time logs from all containers
  - Uses follow mode (-f)
  - Useful for debugging and monitoring

#### Directory Structure Created by Make

```bash
/home/$USER/data/
├── mariadb/     # MariaDB data persistence
└── wordpress/   # WordPress files and uploads
```

**Note**: Replace `$USER` with your actual username in paths

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

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
