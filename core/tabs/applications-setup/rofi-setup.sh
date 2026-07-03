#!/bin/sh -e

. ../common-script.sh

installRofi() {
    if ! command_exists rofi; then
    printf "%b\n" "${YELLOW}Installing Rofi...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm rofi
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add rofi
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy rofi  
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y rofi
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Rofi is already installed.${RC}"
    fi
}


checkEnv
installRofi
