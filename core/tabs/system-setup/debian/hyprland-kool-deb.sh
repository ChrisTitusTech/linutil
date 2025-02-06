#!/bin/bash

. ../../common-script.sh

printf "%b\n" "${YELLOW}Starting Hyprland JaKooLit installation${RC}"
git clone --depth=1 https://github.com/JaKooLit/Debian-Hyprland.git "$HOME/Debian-Hyprland" || { printf "%b\n" "${RED}Failed to clone Jakoolits Debian-Hyprland repo${RC}"; exit 1; }
cd "$HOME/Debian-Hyprland"
chmod +x install.sh
./install.sh