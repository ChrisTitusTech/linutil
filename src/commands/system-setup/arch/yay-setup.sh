#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

installDepend() {
    case $PACKAGER in
        pacman)
            if ! command_exists yay; then
                echo "Installing yay as AUR helper..."
                sudo "$PACKAGER" -S --needed --noconfirm base-devel
                cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R "$USER": ./yay-git
                cd yay-git && makepkg --noconfirm -si
                echo "Yay installed"
            else
                echo "Aur helper already installed"
            fi
            ;;
        *)
            echo "Unsupported package manager: $PACKAGER"
            ;;
    esac
}

checkEnv
installDepend