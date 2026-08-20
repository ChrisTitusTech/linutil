#!/bin/sh -e

. ../../common-script.sh

installFlameshot() {
    if ! command_exists org.flameshot.Flameshot && ! command_exists flameshot; then
        printf "%b\n" "${YELLOW}Installing Flameshot...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flameshot
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flameshot
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm flameshot
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flameshot
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub org.flameshot.Flameshot
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Flameshot is already installed.${RC}"
    fi
}

checkEnv
installFlameshot