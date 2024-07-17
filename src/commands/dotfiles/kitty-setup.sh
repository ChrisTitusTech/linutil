#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which $1 >/dev/null 2>&1
}

setupKitty() {
    echo "Install Kitty if not already installed..."
    if ! command_exists kitty; then
        case ${PKGR} in
            pacman)
                sudo ${PKGR} -S --noconfirm kitty
                ;;
            *)
                sudo ${PKGR} install -y kitty
                ;;
        esac
    else
        echo "Kitty is already installed."
    fi
    echo "Copy Kitty config files"
    if [ -d "${HOME}/.config/kitty" ]; then
        cp -r ${HOME}/.config/kitty ${HOME}/.config/kitty-bak
    fi
    mkdir -p ${HOME}/.config/kitty/
    wget -O ${HOME}/.config/kitty/kitty.conf https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    wget -O ${HOME}/.config/kitty/nord.conf https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

setupKitty
