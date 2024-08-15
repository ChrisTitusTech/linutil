#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

installDepend() {
    case $PACKAGER in
        pacman)
            if ! command_exists paru; then
                echo "Installing paru as AUR helper..."
                sudo "$PACKAGER" -S --needed --noconfirm base-devel
                cd /opt && sudo git clone https://aur.archlinux.org/paru.git && sudo chown -R "$USER": ./paru
                cd paru && makepkg --noconfirm -si
                echo "Paru installed"
            else
                echo "Paru already installed"
            fi
            ;;
        *)
            echo "Unsupported package manager: $PACKAGER"
            ;;
    esac
}

checkEnv
installDepend