#!/bin/bash

# Change the permission for this file before running:
# chmod +x installation_script.sh
# Then run it with:
# su -c 'bash installation_script.sh'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root. Please run it with 'sudo' or 'su'.${NC}"
    exit 1
fi

# Ask for username
echo -e "${YELLOW}Please enter your device username: (This user will have sudo privileges)${NC}"
read -r username

# Update system
echo -e "${BLUE}Updating system...${NC}"
apt-get update -y && apt-get upgrade -y

# Install necessary packages
echo -e "${BLUE}Installing required packages...${NC}"
apt install -y sudo git make curl ssh apt-transport-https ca-certificates software-properties-common

# Add user to sudoers
echo -e "${BLUE}Adding $username to sudo group...${NC}"
adduser "$username" sudo
if ! grep -q "$username ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

# Configure SSH
echo -e "${BLUE}Configuring SSH on port 42...${NC}"
if ! grep -q "Port 42" /etc/ssh/sshd_config; then
    echo "Port 42" >> /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

# Docker installation
echo -e "${BLUE}Installing Docker...${NC}"
if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
fi
if ! grep -q "https://download.docker.com/linux/debian" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
fi

sudo groupadd docker
sudo usermod -aG docker "$username"

# Final Message
echo -e "${GREEN}Setup completed successfully for user $username!${NC}"
echo -e "${YELLOW}Please configure your VM to enable port forwarding (guest 42 <-> host 42) in your MAC.${NC}"
echo -e "${YELLOW}After the reboot, you can start using Docker without sudo.${NC}"

sleep 3

sudo reboot
