#!/bin/sh

. ../../common-script.sh

printf "%b\n" "${YELLOW}Starting Hyprland JaKooLit installation${RC}"

git clone --depth=1 https://github.com/JaKooLit/Fedora-Hyprland.git "$HOME/Fedora-Hyprland" || { printf "%b\n" "${RED}Failed to clone Jakoolits Fedora-Hyprland repo${RC}"; exit 1; }  
cd "$HOME/Fedora-Hyprland" || { printf "%b\n" "${RED}Failed to navigate to Fedora-Hyprland directory${RC}"; exit 1; }
chmod +x install.sh
./install.sh