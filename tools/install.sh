####################################################
# ServUP  Copyright (C) 2025  S2009                #
# LICENSE: GPL-3.0                                 #
# Source Code: https://github.com/S2009-dev/ServUP #
####################################################

#!/bin/sh

# Check if a command can be executed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Format errors
show_err() {
    printf "\033[0;31mAn error occurred:\033[0m %s\n" "$1" >&2
}

# Check if sudo is available
if ! command_exists sudo; then
    show_err "sudo is not installed. Please install sudo to run this script."
    exit 1
fi

# Check if privileges are elevated
if [ "$(id -u)" -ne 0 ]; then
    echo "\033[38;5;208mPrivilege escalation is required. Please enter your sudo password.\033[0m"
    exec sudo "$0" "$@"
    show_err "this script must be executed with administrator privileges."
    exit 1
fi

# Check if ServUP is already installed
if [ -d "/var/lib/servup" ] || id -u servup >/dev/null 2>&1; then
    show_err "ServUP is already installed."
    exit 1
fi

echo "Creating ServUP user..."

# Create a no-shell user and set its home to /var/lib/servup
if ! sudo useradd -r -s /bin/sh -d /var/lib/servup servup; then
    show_err "failed to create the ServUP user."
    exit 1
fi

echo "Creating ServUP directory..."

# Create the ServUP directory and set its owner to the servup user
if ! sudo mkdir -p /var/lib/servup; then
    show_err "failed to create the ServUP directory."
    exit 1
fi

if ! sudo chown servup:servup /var/lib/servup; then
    show_err "failed to chown the ServUP directory."
    exit 1
fi

# Create a SSH key for the servup user and copy it to the authorized_keys file
echo "Generating the ServUP SSH key..."

if ! sudo -u servup mkdir -p /var/lib/servup/.ssh; then
    show_err "failed to create the ServUP SSH directory."
    exit 1
fi

if ! sudo -u servup ssh-keygen -f /var/lib/servup/.ssh/id_rsa -N "" -q; then
    show_err "failed to generate the ServUP SSH key."
    exit 1
fi

if ! sudo -u servup cp /var/lib/servup/.ssh/id_rsa.pub /var/lib/servup/.ssh/authorized_keys; then
    show_err "failed to copy the ServUP SSH key to the authorized_keys file."
    exit 1
fi

echo "Opening ServUP SSH port..."

port=1424

# Check if the default ServUP SSH port is already in use
if sudo ss -tulnp | grep -q ":$port"; then
    # Prompt the user to change the port
    read -p "The port $port is already in use. Please enter a new ServUP SSH port: " port

    # Check if the port is valid
    if ! [ "$port" -eq "$port" ] 2>/dev/null || [ "$port" -lt 1 ] 2>/dev/null || [ "$port" -gt 65535 ] 2>/dev/null; then
       show_err "invalid port number. Please enter an integer between 1 and 65535."
       exit 1
    fi

    # Check if the port is already in use
    if sudo ss -tulnp | grep -q ":$port"; then
       show_err "the port $port is already in use. Please choose another port."
       exit 1
    fi
fi

PORT_LINE="Port $port"
SSH_CONF="/etc/ssh/sshd_config"

# Check if the port is already in the SSH configuration
if sudo grep -F -q "$PORT_LINE" "$SSH_CONF"; then
    show_err "the port $port is already set in the SSH configuration."
    exit 1
fi

# Add the port to the SSH configuration
if ! sudo echo "$PORT_LINE" >> "$SSH_CONF"; then
    show_err "failed to add the port $port to the SSH configuration."
    exit 1
fi

echo "Applying changes to SSH configuration..."

# Restart the SSH service
if command_exists systemctl; then
    sudo systemctl restart sshd || failed=1
elif command_exists service; then
    sudo service ssh restart || failed=1
else
    failed=1
fi

[ "$failed" = 1 ] && show_err "could not restart SSH service. Please restart it manually."

echo "Finishing installation..."

# Create the directory for the remote files
if ! sudo -u servup mkdir -p /var/lib/servup/remote; then
    show_err "could not create the ServUP directory for the remote files."
fi

# Check if iptables is installed
if command_exists iptables; then
    # Prompt the user to install the firewall tool
    read -p "It seems that you have iptables installed. Do you want to add the Github Actions IPs to the firewall using our tool? (y/N): " answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/S2009-dev/ServUP/main/tools/firewall.sh)"; then 
           show_err "failed to install our firewall tool. You can install it manually with 'sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/S2009-dev/ServUP/main/tools/firewall.sh)\"'"
        fi
    fi
fi

# Finish installation
echo "\n\n\033[1;32mInstallation completed successfully!\033[0m"
echo "SSH Port: $port"
echo "ServUP SSH Key:"

if ! sudo cat /var/lib/servup/.ssh/id_rsa | sed "s/.*/\o033[90m&\o033[0m/"; then
    show_err "could not display the key. You can find it manually at '/var/lib/servup/.ssh/id_rsa'"
fi