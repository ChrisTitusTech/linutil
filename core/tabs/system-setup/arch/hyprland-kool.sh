#!/bin/bash

. ../../common-script.sh

echo "Hyprland JaKooLit"

if ! pacman -Q base-devel &>/dev/null; then
    printf "%b\n" "${YELLOW}Installing base-devel...${RC}"
    sudo pacman -S --noconfirm base-devel
fi

git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git "$HOME/Arch-Hyprland" || { printf "%b\n" "${RED}Failed to clone Jakoolits Arch-Hyprland repo${RC}"; exit 1; }
cd "$HOME/Arch-Hyprland"
chmod +x install.sh
./install.sh
