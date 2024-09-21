#!/bin/sh -e

. ../common-script.sh

installBottles() {
    if ! command_exists flatpak; then
    printf "%b\n" "${YELLOW}Installing Bottles...${RC}"
        case "$PACKAGER" in
            *)
                . ./setup-flatpak.sh
                flatpak install -y flathub com.usebottles.bottles
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Bottles is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installBottles