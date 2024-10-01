#!/bin/sh -e

. ../common-script.sh

checkWpsOfficeInstallation() {
    case "$PACKAGER" in
        pacman)
            command_exists wps
            ;;
        *)
            checkFlatpak
            flatpak_app_exists com.wps.Office
            ;;
    esac
}

installWpsOffice() {
    if ! checkWpsOfficeInstallation; then
        printf "%b\n" "${YELLOW}Installing WPS Office...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm wps-office
                ;;
            *)
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