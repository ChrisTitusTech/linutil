#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which $1 >/dev/null 2>&1
}

checkEnv() {
    checkCommandRequirements 'curl groups sudo'
    checkPackageManager 'apt-get dnf pacman zypper nix-env'
    checkSuperUser
    checkDistro
}

setupAlacritty() {
    echo "Install Alacritty if not already installed..."
    if ! command_exists alacritty; then
        case ${PACKAGER} in
            pacman)
                sudo ${PACKAGER} -S --noconfirm alacritty
                ;;
            nix-env)
                sudo ${PACKAGER} -iA nixos.alacritty
                ;;
            *)
                sudo ${PACKAGER} install -y alacritty
                ;;
        esac
    else
        echo "alacritty is already installed."
    fi
    echo "Copy alacritty config files"
    if [ -d "${HOME}/.config/alacritty" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    wget -O "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    wget -O "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
}

checkEnv
setupAlacritty