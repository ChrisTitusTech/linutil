#!/bin/sh

. ../../common-script.sh

printf "%b\n" "${YELLOW}Starting Hyprland JaKooLit installation${RC}"

git clone -b 24.04 --depth=1 https://github.com/JaKooLit/Ubuntu-Hyprland.git "$HOME/Ubuntu-Hyprland-24.04" || { printf "%b\n" "${RED}Failed to clone Jakoolits Ubuntu-Hyprland repo${RC}"; exit 1; }
cd "$HOME/Ubuntu-Hyprland-24.04" || { printf "%b\n" "${RED}Failed to navigate to Ubuntu-Hyprland-24.04 directory${RC}"; exit 1; }
chmod +x install.sh
./install.sh