#!/bin/sh -e

. ../common-script.sh

installEvince() {
    if ! command_exists evince; then
        printf "%b\n" "${YELLOW}Installing Evince...${RC}"
        case "$PACKAGER" in
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm evince
                ;;
            *)
                elevated_execution "$PACKAGER" install -y evince
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Evince is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installEvince