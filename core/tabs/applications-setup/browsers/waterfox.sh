#!/bin/sh -e

. ../../common-script.sh

installWaterfox() {
    if ! flatpak_app_installed net.waterfox.waterfox && ! command_exists waterfox; then
        printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
        if try_flatpak_install net.waterfox.waterfox; then
            return 0
        fi
        case "$PACKAGER" in
            pacman)
		        "$AUR_HELPER" -S --needed --noconfirm waterfox-bin
                ;;
            *)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
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
