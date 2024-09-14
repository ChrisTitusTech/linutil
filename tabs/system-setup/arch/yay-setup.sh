#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

installDepend() {
    case $PACKAGER in
        pacman)
            if ! command_exists yay; then
                echo "Installing yay as AUR helper..."
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm base-devel
                cd /opt && $ESCALATION_TOOL git clone https://aur.archlinux.org/yay-bin.git && $ESCALATION_TOOL chown -R "$USER": ./yay-bin
                cd yay-bin && makepkg --noconfirm -si
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
checkEscalationTool
installDepend
