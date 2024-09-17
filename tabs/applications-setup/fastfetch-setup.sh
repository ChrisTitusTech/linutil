#!/bin/sh -e

. ../common-script.sh

setupFastfetch() {
    echo "Installing Fastfetch if not already installed..."
    if ! command_exists fastfetch; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --needed --noconfirm fastfetch
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y fastfetch
                ;;
        esac
    else
        echo "Fastfetch is already installed."
    fi
}

setupFastfetchConfig() {
    echo "Copying Fastfetch config files..."
    if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
        cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
}

checkEnv
checkEscalationTool
setupFastfetch
setupFastfetchConfig