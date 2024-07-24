#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which "$1" >/dev/null 2>&1
}

checkEnv() {
    checkCommandRequirements 'curl groups sudo'
    checkPackageManager 'apt-get dnf pacman zypper nix-env'
    checkSuperUser
    checkDistro
}

setupRofi() {
    echo "Install Rofi if not already installed..."
    if ! command_exists rofi; then
        case "$PACKAGER" in
            pacman)
                sudo "$PACKAGER" -S --noconfirm rofi
                ;;
            nix-env)
                sudo "$PACKAGER" -iA nixos.rofi
                ;;
            *)
                sudo "$PACKAGER" install -y rofi
                ;;
        esac
    else
        echo "Rofi is already installed."
    fi
    echo "Copy Rofi config files"
    if [ -d "$HOME/.config/rofi" ]; then
        cp -r "$HOME/.config/rofi" "$HOME/.config/rofi.bak"
    fi
    mkdir -p "$HOME/.config/rofi"
    wget -O "$HOME/.config/rofi/powermenu.sh" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/powermenu.sh
    chmod +x "$HOME/.config/rofi/powermenu.sh"
    wget -O "$HOME/.config/rofi/config.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/config.rasi
    mkdir -p "$HOME/.config/rofi/themes"
    wget -O "$HOME/.config/rofi/themes/nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/nord.rasi
    wget -O "$HOME/.config/rofi/themes/sidetab-nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/sidetab-nord.rasi
    wget -O "$HOME/.config/rofi/themes/powermenu.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/powermenu.rasi
}

checkEnv
setupRofi
