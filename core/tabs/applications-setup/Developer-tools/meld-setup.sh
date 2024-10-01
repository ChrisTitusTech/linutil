#!/bin/sh -e

. ../../common-script.sh

checkMeldInstallation() {
    case "$PACKAGER" in
        pacman|apt-get|nala)
            command_exists meld
            ;;
        *)
            checkFlatpak
            flatpak_app_exists org.gnome.meld
            ;;
    esac
}

installMeld() {
    if ! checkMeldInstallation; then
        printf "%b\n" "${YELLOW}Installing Meld...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm meld
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" -y install meld
                ;;
            *)
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