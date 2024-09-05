#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

installDepend() {
    case $PACKAGER in
        pacman)
            if ! command_exists paru; then
                echo "Installing paru as AUR helper..."
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm base-devel
                cd /opt && $ESCALATION_TOOL git clone https://aur.archlinux.org/paru.git && $ESCALATION_TOOL chown -R "$USER": ./paru
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
checkEscalationTool
installDepend
