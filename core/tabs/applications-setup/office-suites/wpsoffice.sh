#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.wps.Office"
APP_UNINSTALL_PKGS=""


installWpsOffice() {
    if ! flatpak_app_installed com.wps.Office && ! command_exists wps; then
        printf "%b\n" "${YELLOW}Installing WPS Office...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm wps-office
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists wps; then
            return 0
        fi
        if try_flatpak_install com.wps.Office; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}WPS Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installWpsOffice
