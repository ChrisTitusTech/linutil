#!/bin/sh -e

. ../../common-script.sh

installWpsOffice() {
    if ! flatpak_app_installed com.wps.Office && ! command_exists wps; then
        printf "%b\n" "${YELLOW}Installing WPS Office...${RC}"
        if try_flatpak_install com.wps.Office; then
            return 0
        fi
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm wps-office
                ;;
            *)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}WPS Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installWpsOffice
