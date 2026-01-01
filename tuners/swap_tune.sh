#!/usr/bin/env bash
# Memory, Swap, and Zswap tuning for Linux

set -euo pipefail

# --- 1. Swapfile setup (persistent) ---
SWAPFILE=/swapfile
SWAPSIZE=32G

echo "Turning off any existing swap..."
sudo swapoff -a

if [ ! -f "$SWAPFILE" ]; then
    echo "Creating $SWAPSIZE swapfile at $SWAPFILE..."
    sudo fallocate -l $SWAPSIZE $SWAPFILE
    sudo chmod 600 $SWAPFILE
    sudo mkswap $SWAPFILE
fi

echo "Enabling swap..."
sudo swapon --priority 100 $SWAPFILE

# Ensure persistent swap across reboots
if ! grep -qF "$SWAPFILE" /etc/fstab; then
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# --- 2. Kernel tuning (runtime and persistent) ---
# Swappiness: lower = less swap aggressiveness
SWAPPINESS=10
sudo sysctl -w vm.swappiness=$SWAPPINESS

# VFS cache pressure: lower = keep directory/inode cache longer
VFS_CACHE_PRESSURE=50
sudo sysctl -w vm.vfs_cache_pressure=$VFS_CACHE_PRESSURE

# Make persistent by adding to /etc/sysctl.conf if not already present
sudo sed -i '/vm.swappiness/d' /etc/sysctl.conf
sudo sed -i '/vm.vfs_cache_pressure/d' /etc/sysctl.conf
echo "vm.swappiness=$SWAPPINESS" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=$VFS_CACHE_PRESSURE" | sudo tee -a /etc/sysctl.conf

# --- 3. Zswap setup via kernel parameters ---
# For current session (runtime)
if [ -d /sys/module/zswap ]; then
    echo 1 | sudo tee /sys/module/zswap/parameters/enabled
    echo lz4 | sudo tee /sys/module/zswap/parameters/compressor
    echo 20 | sudo tee /sys/module/zswap/parameters/max_pool_percent
fi

# Persistent Zswap via GRUB
GRUB_CMDLINE="zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20"
if ! grep -q "zswap.enabled=1" /etc/default/grub; then
    sudo sed -i "s|^GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 $GRUB_CMDLINE\"|" /etc/default/grub
    sudo update-grub
fi

# --- 4. Verification ---
echo "Swap status:"
swapon --show
free -h
echo "Zswap enabled:"
cat /sys/module/zswap/parameters/enabled
echo "Zswap compressor:"
cat /sys/module/zswap/parameters/compressor
echo "Zswap max pool percent:"
cat /sys/module/zswap/parameters/max_pool_percent

echo "Memory tuning completed. Reboot recommended for persistent Zswap parameters."

