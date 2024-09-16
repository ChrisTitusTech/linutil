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
    if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.yml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.yml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.yml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.yml"

    alacritty_version=$(alacritty --version | awk '{print $2}')
    if [ "$(printf '%s\n' "$alacritty_version" "0.13.0" | sort -V | head -n1)" = "0.13.0" ]; then    # Check if alacritty is < 0.13.0  https://alacritty.org/changelog_0_13_0.html#Changed
        echo "Alacritty version is gearter or equal to 0.13.0, migrating config files..."
        if alacritty migrate; then
            command rm -f "${HOME}/.config/alacritty/*.yml"                                          # Using 'command' to avoid alias
        else
            echo "Failed to migrate alacritty config files."
        fi
    fi
}

checkEnv
checkEscalationTool
setupAlacritty
