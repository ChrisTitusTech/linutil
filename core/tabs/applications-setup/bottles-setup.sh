#!/bin/sh -e

. ../common-script.sh

install_bottles() {
    printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
    . ./setup-flatpak.sh
    flatpak install -y flathub com.usebottles.bottles
    printf "%b\n" "${GREEN}Bottles installed successfully. Restart the system to apply changes...${RC}"
}

checkEnv
checkEscalationTool
install_bottles