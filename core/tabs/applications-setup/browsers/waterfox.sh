#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="net.waterfox.waterfox"
APP_UNINSTALL_PKGS=""


installWaterfox() {
    if ! flatpak_app_installed net.waterfox.waterfox && ! command_exists waterfox; then
        printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
        case "$PACKAGER" in
            pacman)
		        "$AUR_HELPER" -S --needed --noconfirm waterfox-bin
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists waterfox; then
            return 0
        fi
        if try_flatpak_install net.waterfox.waterfox; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Waterfox is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installWaterfox
