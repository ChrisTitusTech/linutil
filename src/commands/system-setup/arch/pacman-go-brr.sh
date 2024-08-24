#!/bin/bash

# This script optimizes Pacman (Arch Linux package manager) configuration:
# 1. Updates mirror list for faster downloads using reflector
# 2. Modifies pacman.conf to enhance performance and aesthetics
# Key features:
# - Selects fastest mirrors based on download rates
# - Configures parallel downloads for improved speed
# - Enables colorized output for better readability

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges. Please enter your password."
    exec sudo "$0" "$@"
    exit $?
fi

# Function to check and install dependencies
# Usage: dependency package_name
dependency() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed. Installing..."
        pacman -S --noconfirm $1
    fi
}

# Check and install required packages
echo "Checking and installing required packages..."
dependency reflector  # Used for updating mirror list
dependency sed        # Used for text manipulation

clear

# User input for configuration
echo "Configuring mirror..."
read -p "Enter the number of mirrors to use (default is 50): " MIRROR_COUNT
MIRROR_COUNT=${MIRROR_COUNT:-50}

read -p "Enter the number of parallel downloads (default is 7): " PARALLEL_DOWNLOADS
PARALLEL_DOWNLOADS=${PARALLEL_DOWNLOADS:-7}

# Update mirror list using reflector
echo "Updating mirror list..."
sudo reflector --verbose --sort rate -l $MIRROR_COUNT --save /etc/pacman.d/mirrorlist

# Modify pacman configuration
echo "Modifying pacman.conf..."

# Uncomment ParallelDownloads option
sed -i '/^# *ParallelDownloads/s/^# *//' /etc/pacman.conf

# Set the number of parallel downloads
sed -i "s/^ParallelDownloads *= *[0-9]*/ParallelDownloads = $PARALLEL_DOWNLOADS/" /etc/pacman.conf

# Uncomment Color option for colorized output
sed -i '/^# *Color/s/^# *//' /etc/pacman.conf

# Add ILoveCandy option if not present
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    echo "Adding ILoveCandy option..."
    sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
fi

echo "Setup complete! Mirror list updated and pacman.conf modified with $PARALLEL_DOWNLOADS parallel downloads."