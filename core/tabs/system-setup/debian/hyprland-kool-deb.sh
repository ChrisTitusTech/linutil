#!/bin/bash

echo "Hyprland JaKooLit"
git clone --depth=1 https://github.com/JaKooLit/Debian-Hyprland.git "$HOME/Debian-Hyprland" || { printf "%b\n" "${RED}Failed to clone Jakoolits Debian-Hyprland repo${RC}"; exit 1; }
cd "$HOME/Debian-Hyprland"
chmod +x install.sh
./install.sh