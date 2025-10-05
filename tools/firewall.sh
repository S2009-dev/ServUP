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

# Show a progress bar
progress_bar() {
    percent="$1"
    progress=$((percent / 2))
    bar=$(printf '#%.0s' $(seq 1 $progress))

    if [ "$percent" -eq 100 ]; then
        color="\033[92m"
    elif [ "$percent" -ge 90 ]; then
        color="\033[32m"
    elif [ "$percent" -ge 75 ]; then
        color="\033[96m"
    elif [ "$percent" -ge 50 ]; then
        color="\033[94m"
    elif [ "$percent" -ge 25 ]; then
        color="\033[34m"
    else
        color="\033[90m"
    fi

    printf "\rProgress: ${color}[%-50s] %d%%\033[0m" "$bar" "$percent"

    if [ "$percent" -eq 100 ]; then
        printf "\n"
    fi
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

# Check if curl is available
if ! command_exists curl; then
    show_err "curl is not installed. Please install curl to run this script."
    exit 1
fi

# Check if iptables is available
if ! command_exists iptables; then
    show_err "iptables is not installed. Please install iptables to run this script."
    exit 1
fi

# Set the port to the one provided by the user or default to 1424
port=${1:-1424}

# Check if the port is valid
if ! [ "$port" -eq "$port" ] 2>/dev/null || [ "$port" -lt 1 ] 2>/dev/null || [ "$port" -gt 65535 ] 2>/dev/null; then
    show_err "the provided port is invalid. Please provide an integer between 1 and 65535."
    exit 1
fi

# Get Github Actions IPs
response=$(curl -s https://api.github.com/meta)
if [ -z "$response" ]; then
    show_err "Failed to fetch GitHub Actions IPs."
    exit 1
fi

# Extract IPv4 and IPv6 addresses in temp files
ipv4_file=$(mktemp)
ipv6_file=$(mktemp)

echo "$response" | jq -r '.actions[]' | while read -r ip; do
    case "$ip" in
        *:*) echo "$ip" >> "$ipv6_file" ;;  # IPv6
        *) echo "$ip" >> "$ipv4_file" ;;    # IPv4
    esac
done

total_ipv4=$(wc -l < "$ipv4_file")
current_ip=0

echo "Adding Github Actions IPv4 list to the firewall (ServUP SSH port: $port)..."

# Add IPv4 rules
while IFS= read -r ip; do
    current_ip=$((current_ip + 1))
    percent=$((current_ip * 100 / total_ipv4))

    progress_bar "$percent"

    if ! sudo /usr/sbin/iptables -A INPUT -p tcp -m tcp --dport "$port" -s "$ip" -j ACCEPT; then
        show_err "\ncan't add IPv4 rule for $ip."
    fi
done < "$ipv4_file"

# Save IPv4 rules
if ! sudo /usr/sbin/iptables-save > /etc/iptables/rules.v4; then
    show_err "can't save IPv4 rules."
    exit 1
fi

# Cleanup
rm -f "$ipv4_file" "$ipv6_file"

echo "Github Actions IPs were successfully added to the firewall !"