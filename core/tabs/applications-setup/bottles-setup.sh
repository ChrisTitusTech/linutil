#!/bin/sh -e

. ../common-script.sh

installBottles() {
    if ! command_exists com.usebottles.bottles; then
        printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
        flatpak install -y flathub com.usebottles.bottles
    else
        printf "%b\n" "${GREEN}Bottles is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkFlatpak
installBottles