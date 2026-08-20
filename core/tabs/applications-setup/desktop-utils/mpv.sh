#!/bin/sh -e

. ../../common-script.sh

installMPV() {
    if ! command_exists io.mpv.Mpv && ! command_exists mpv; then
        printf "%b\n" "${YELLOW}Installing MPV...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y mpv
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y mpv
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm mpv
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add mpv
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub io.mpv.Mpv
                ;;
        esac
    else
        printf "%b\n" "${GREEN}MPV is already installed.${RC}"
    fi
}

checkEnv
installMPV