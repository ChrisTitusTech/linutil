#!/bin/sh -e

. ../common-script.sh

setupAlacritty() {
    echo "Install Alacritty if not already installed..."
    if ! command_exists alacritty; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL ${PACKAGER} -S --needed --noconfirm alacritty
                ;;
            *)
                $ESCALATION_TOOL ${PACKAGER} install -y alacritty
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

    alacritty_version=$(alacritty --version | awk '{print $2}')
    if [ "$(printf '%s\n' "$alacritty_version" "0.13.0" | sort -V | head -n1)" = "0.13.0" ]; then
        echo "Alacritty version is newer than 0.13.0, migrating config files..."
        if alacritty migrate; then
            # using 'command' to avoid alias
            command rm -f "${HOME}/.config/alacritty/*.yml"
        else
            echo "Failed to migrate alacritty config files."
        fi
    fi
}

checkEnv
checkEscalationTool
setupAlacritty
