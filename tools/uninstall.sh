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

# Prompt the user to confirm the uninstallation
read -p "Are you sure you want to uninstall ServUP? (y/N): " answer

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Check if sudo is available
if ! command_exists sudo; then
    show_err "sudo is not installed. Please install sudo to run this script."
    exit 1
fi

# Set the port to the one provided by the user or default to 1424
port=${1:-1424}

# Check if the port is valid
if ! [ "$port" -eq "$port" ] 2>/dev/null || [ "$port" -lt 1 ] 2>/dev/null || [ "$port" -gt 65535 ] 2>/dev/null; then
    show_err "the provided port is invalid. Please provide an integer between 1 and 65535."
    exit 1
fi

# Check if privileges are elevated
if [ "$(id -u)" -ne 0 ]; then
    echo "\033[38;5;208mPrivilege escalation is required. Please enter your sudo password.\033[0m"
    exec sudo "$0" "$@"
    show_err "this script must be executed with administrator privileges."
    exit 1
fi

echo "Removing ServUP user..."

# Remove ServUP user
if ! sudo userdel -r servup; then
    show_err "failed to remove the ServUP user. Please remove it manually."
fi

echo "Removing ServUP SSH port..."

PORT_LINE="Port $port"
SSH_CONF="/etc/ssh/sshd_config"

# Remove the port from the SSH configuration
if ! sudo sed -i "/$PORT_LINE/d" "$SSH_CONF"; then
    show_err "failed to remove the port $port from the SSH configuration."
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

# Finish uninstallation
echo "\n\033[1;32mUninstallation completed successfully!\033[0m"
echo "Hope to see you again soon!"