#!/bin/sh -e

. ../common-script.sh

installKitty() {
    echo "Installing Kitty..."
    if ! command_exists kitty; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --needed --noconfirm kitty
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y kitty
                ;;
        esac
    else
        echo "Kitty is already installed."
    fi
}

setupKittyConfig() {
    echo "Copying Kitty configuration files..."
    if [ -d "${HOME}/.config/kitty" ] && [ ! -d "${HOME}/.config/kitty-bak" ]; then
        cp -r "${HOME}/.config/kitty" "${HOME}/.config/kitty-bak"
    fi
    mkdir -p "${HOME}/.config/kitty/"
    curl -sSLo "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    curl -sSLo "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
checkEscalationTool
installKitty
setupKittyConfig