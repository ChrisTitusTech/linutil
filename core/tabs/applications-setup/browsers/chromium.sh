#!/bin/sh -e

. ../../common-script.sh

installChromium() {
if ! command_exists chromium; then
    printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
    case "$PACKAGER" in
        pacman)
            elevated_execution "$PACKAGER" -S --needed --noconfirm chromium
            ;;
        *)
            elevated_execution "$PACKAGER" install -y chromium
            ;;
    esac
else
    printf "%b\n" "${GREEN}Chromium Browser is already installed.${RC}"
fi
}

checkEnv
checkEscalationTool
installChromium