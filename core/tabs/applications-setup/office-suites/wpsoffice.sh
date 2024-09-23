#!/bin/sh -e

. ../common-script.sh

installWpsOffice() {
    if ! command_exists com.wps.Office; then
        printf "%b\n" "${YELLOW}Installing WPS Office...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm wps-office
                ;;
            *)
                . ./setup-flatpak.sh
                flatpak install flathub com.wps.Office
                ;;
        esac
    else
        printf "%b\n" "${GREEN}WPS Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAurHelper
installWpsOffice