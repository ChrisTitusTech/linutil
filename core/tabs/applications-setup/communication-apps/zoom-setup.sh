#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="us.zoom.Zoom"
APP_UNINSTALL_PKGS=""


installZoom() {
    if ! flatpak_app_installed us.zoom.Zoom && ! command_exists zoom; then
        printf "%b\n" "${YELLOW}Installing Zoom...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm zoom
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists zoom; then
            return 0
        fi
        if try_flatpak_install us.zoom.Zoom; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Zoom is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installZoom
