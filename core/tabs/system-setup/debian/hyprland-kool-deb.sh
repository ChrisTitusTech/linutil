#!/bin/bash

echo "Hyprland JaKooLit"
git clone --depth=1 https://github.com/JaKooLit/Debian-Hyprland.git ~/Debian-Hyprland
cd "$HOME/Debian-Hyprland"
chmod +x install.sh
./install.sh