#!/bin/sh -e

. ../../common-script.sh

installWaterfox() {
    if ! command_exists waterfox; then
        printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
        case "$PACKAGER" in
            pacman)
		"$AUR_HELPER" -S --needed --noconfirm waterfox-bin
                ;;
            *)
		. ../setup-flatpak.sh
                flatpak install -y flathub net.waterfox.waterfox
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Waterfox is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installWaterfox
