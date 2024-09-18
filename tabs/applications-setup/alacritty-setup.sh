#!/bin/sh -e

. ../common-script.sh

installAlacritty() {
    echo "Installing Alacritty..."
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
        echo "Alacritty is already installed."
    fi
}

setupAlacrittyConfig() {
    echo "Copying Alacritty configuration files..."
    if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
}

checkEnv
checkEscalationTool
installAlacritty
setupAlacrittyConfig