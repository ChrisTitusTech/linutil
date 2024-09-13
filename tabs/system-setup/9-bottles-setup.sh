#!/bin/sh -e

. ../common-script.sh

install_bottles() {
    printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
    if ! command_exists flatpak; then
    case $PACKAGER in
        pacman)
            $ESCALATION_TOOL ${PACKAGER} -Syu --noconfirm flatpak         
            ;;
        apt-get)
            $ESCALATION_TOOL ${PACKAGER} update && $ESCALATION_TOOL ${PACKAGER} install -y flatpak
            ;;
        dnf)
            $ESCALATION_TOOL ${PACKAGER} install -y flatpak
            ;;
        zypper)
            $ESCALATION_TOOL ${PACKAGER} install flatpak
            ;;
        *)
            printf "%b\n" "${RED}Your Linux distribution is not supported by this script.${RC}"
            printf "%b\n" "${YELLOW}You can try installing Bottles using Flatpak manually:${RC}"
            echo "1. Install Flatpak: https://flatpak.org/setup/"
            echo "2. Install Bottles: flatpak install flathub com.usebottles.bottles"
            ;;
    esac
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub com.usebottles.bottles
    printf "%b\n" "${GREEN}Bottles installed successfully. Restart the system to apply changes...${RC}"
}

checkEnv
checkEscalationTool
install_bottles
