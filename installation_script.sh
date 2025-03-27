#!/bin/bash

# change the permission for this file then please RUN this script with 
# su -c 'bash installation_script.sh'

# Check if the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please run it with 'sudo' or 'su'."
    exit 1
fi

echo "Please enter your username:"
read username

#SUDO 
apt install sudo -y
echo "enter password for your root password"
su - 


#USER
adduser $username sudo
echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers

#SSH
apt install ssh -y
echo "port 42" >> /etc/ssh/ssh_config
echo "port 42" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "Please configure your VM to enable port forwarding guest 42 host 42 in your MAC"

#DOCKER & docker compose

apt-get update -y
apt-get install apt-transport-https ca-certificates curl software-properties-common -y 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io -y 
-groupadd docker
usermod -aG docker $USER

echo "Setup completed successfully for user $username!"

