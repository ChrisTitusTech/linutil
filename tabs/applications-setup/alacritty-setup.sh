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

    alacritty_version=$(alacritty --version | awk '{print $2}')
    if [ "$(printf '%s\n' "$alacritty_version" "0.13.0" | sort -V | head -n1)" != "0.13.0" ]; then        # Check if alacritty is >= 0.13.0  https://alacritty.org/changelog_0_13_0.html#Changed
        echo
        echo "Only alacritty >= 0.13.0 is supported."
        exit 1
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
checkEscalationTool
setupAlacritty
