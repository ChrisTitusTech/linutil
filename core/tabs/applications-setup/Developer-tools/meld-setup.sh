#!/bin/sh -e

. ../../common-script.sh

installMeld() {
    if ! command_exists org.gnome.meld && ! command_exists meld; then
        printf "%b\n" "${YELLOW}Installing Meld...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm meld
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" -y install meld
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add meld
                ;;
            *)
                checkFlatpak
                flatpak install -y flathub org.gnome.meld
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Meld is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installMeld