#!/bin/sh -e

. ../common-script.sh

install_bottles() {
    printf "%b" "${YELLOW}Do you want to install Bottles? (Y/n): ${RC}"
    read -r install_choice
    if [ "$install_choice" != "n" ] && [ "$install_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
        . ./setup-flatpak.sh
        flatpak install -y flathub com.usebottles.bottles
        printf "%b\n" "${GREEN}Bottles installed successfully.${RC}"
    else
        printf "%b\n" "${GREEN}Skipping Bottles installation.${RC}"
    fi
}

checkEnv
checkEscalationTool
install_bottles