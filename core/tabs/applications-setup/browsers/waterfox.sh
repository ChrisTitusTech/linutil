#!/bin/sh -e

. ../../common-script.sh

installWaterfox() {
    if ! command_exists net.waterfox.waterfox && ! command_exists waterfox; then
        printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
        case "$PACKAGER" in
            pacman)
		        "$AUR_HELPER" -S --needed --noconfirm waterfox-bin
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub net.waterfox.waterfox
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Waterfox is already installed.${RC}"
    fi
}

checkEnv
installWaterfox
