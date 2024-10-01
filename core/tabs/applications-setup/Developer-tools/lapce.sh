#!/bin/sh -e

. ../../common-script.sh

installLapce() {
    if ! command_exists lapce; then
        printf "%b\n" "${YELLOW}Installing Lapce...${RC}"
        case "$PACKAGER" in
            pacman)
		"$AUR_HELPER" -S --needed --noconfirm lapce
                ;;
            *)
		. ../setup-flatpak.sh
                flatpak install flathub dev.lapce.lapce
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Lapce is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installLapce
