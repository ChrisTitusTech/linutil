#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.brave.Browser"
APP_UNINSTALL_PKGS="brave-browser"


installBrave() {
    if ! command_exists com.brave.Browser && ! command_exists brave; then
        printf "%b\n" "${YELLOW}Installing Brave...${RC}"
        curl -fsS https://dl.brave.com/install.sh | sh
    else
        printf "%b\n" "${GREEN}Brave Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installBrave
