#!/bin/sh -e

. ../common-script.sh

installOkular() {
    if ! command_exists okular; then
        printf "%b\n" "${YELLOW}Installing Okular...${RC}"
        case "$PACKAGER" in
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm okular
                ;;
            *)
                elevated_execution "$PACKAGER" install -y okular
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Okular is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installOkular