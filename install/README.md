# Inception Installation Guide

## Prerequisites
Before running the installation script, ensure that you have the following setup:

- A virtual machine (VM) running **Debian** or **Ubuntu**.
- Network ports configured:
  - **443:443** for Nginx
  - **42:42** for SSH between the host and the guest
- `curl` must be installed on your system.

## Installing Curl
If `curl` is not installed, you can install it using the following command:
```sh
su -c "apt install curl"
```

## Downloading the Installation Script
To download the installation script, run the following command:
```sh
curl -O https://raw.githubusercontent.com/Dice42/Inception/main/install.sh
```

## Setting Up Execution Permissions
Once downloaded, modify the file permissions to make it executable:
```sh
chmod +x install.sh
```

## Running the Installation Script
Execute the script with superuser privileges:
```sh
su -c "bash install.sh"
```

## Notes
- Ensure you have the necessary permissions to execute the script.
- Double-check that your VM's network settings are correctly configured before running the script.
- If you encounter any issues, verify that `curl` is properly installed and your VM network ports are correctly mapped.

Happy coding! 🚀

