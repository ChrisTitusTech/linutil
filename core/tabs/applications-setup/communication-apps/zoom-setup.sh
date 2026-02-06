#!/bin/sh -e

. ../../common-script.sh

installZoom() {
    if ! flatpak_app_installed us.zoom.Zoom && ! command_exists zoom; then
        printf "%b\n" "${YELLOW}Installing Zoom...${RC}"
        if try_flatpak_install us.zoom.Zoom; then
            return 0
        fi
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm zoom
                ;;
            *)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
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
