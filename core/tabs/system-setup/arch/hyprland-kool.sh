#!/bin/bash

echo "Hyprland JaKooLit"

if ! pacman -Q base-devel &>/dev/null; then
    echo "Installing base-devel..."
    sudo pacman -S --noconfirm base-devel
fi

git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
cd "$HOME/Arch-Hyprland"
chmod +x install.sh
./install.sh
