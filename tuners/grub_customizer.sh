#!/bin/bash
# Grub Customizer Installer for Ubuntu 24.04 (Noble)
# Works on both UEFI and Legacy systems
# WARNING: Back up your grub configs before running this script!

set -e

echo "### Step 0: Backing up existing GRUB configuration ###"
sudo cp -a /etc/grub.d /etc/grub.d.backup
sudo cp /etc/default/grub /etc/default/grub.backup
echo "Backup completed."

echo "### Step 1: Installing build dependencies ###"
sudo apt update
sudo apt install -y \
    bzr cmake make g++ \
    libgtkmm-3.0-dev libssl-dev libblkid-dev libmount-dev libglibmm-2.4-dev \
    libarchive-dev

echo "### Step 2: Downloading Grub Customizer source ###"
if [ -d "$HOME/grub-customizer" ]; then
    echo "Existing grub-customizer directory found. Removing..."
    rm -rf "$HOME/grub-customizer"
fi

bzr branch lp:grub-customizer "$HOME/grub-customizer"

echo "### Step 3: Building Grub Customizer ###"
cd "$HOME/grub-customizer"
rm -rf CMakeFiles CMakeCache.txt
cmake .
make

echo "### Step 4: Installing Grub Customizer ###"
sudo make install

echo "### Installation complete! ###"
echo "You can now run Grub Customizer with:"
echo "sudo grub-customizer"
