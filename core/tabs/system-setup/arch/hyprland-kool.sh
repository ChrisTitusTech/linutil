#!/bin/bash

# Check if base-devel is installed, install if not
if ! pacman -Q base-devel &>/dev/null; then
    echo "Installing base-devel..."
    sudo pacman -S --noconfirm base-devel
fi

git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
cd ~/Arch-Hyprland
chmod +x install.sh
./install.sh
