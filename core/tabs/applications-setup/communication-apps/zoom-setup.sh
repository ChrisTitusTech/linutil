#!/bin/sh -e

. ../../common-script.sh

checkZoomInstallation() {
    case "$PACKAGER" in
        pacman)
            command_exists zoom
            ;;
        *)
            checkFlatpak
            flatpak_app_exists us.zoom.Zoom
            ;;
    esac
}

installZoom() {
    if ! checkZoomInstallation; then
        printf "%b\n" "${YELLOW}Installing Zoom...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm zoom
                ;;
            *)
                flatpak install -y flathub us.zoom.Zoom
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Zoom is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installZoom