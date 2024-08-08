#!/bin/sh -e

. ./common-script.sh

setupAlacritty() {
    echo "Install Alacritty if not already installed..."
    if ! command_exists alacritty; then
        case ${PACKAGER} in
            pacman)
                sudo ${PACKAGER} -S --noconfirm alacritty
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
