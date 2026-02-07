#!/bin/sh -e

. ../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="com.usebottles.bottles flathub"


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
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


checkFlatpak
installBottles
