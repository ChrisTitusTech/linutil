#!/bin/sh -e

. ./common-script.sh

setupKitty() {
    echo "Install Kitty if not already installed..."
    if ! command_exists kitty; then
        case ${PACKAGER} in
            pacman)
                sudo "${PACKAGER}" -S --noconfirm kitty
                ;;
            *)
                sudo "${PACKAGER}" install -y kitty
                ;;
        esac
    else
        echo "Kitty is already installed."
    fi
    echo "Copy Kitty config files"
    if [ -d "${HOME}/.config/kitty" ]; then
        cp -r "${HOME}"/.config/kitty "${HOME}"/.config/kitty-bak
    fi
    mkdir -p "${HOME}"/.config/kitty/
    wget -O "${HOME}"/.config/kitty/kitty.conf https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    wget -O "${HOME}"/.config/kitty/nord.conf https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
setupKitty
