#!/bin/sh -e

. ../../common-script.sh

installNgrok() {
    if ! command_exists ngrok; then
        printf "%b\n" "${YELLOW}Installing Ngrok...${RC}"
        curl -sSLo https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | "$ESCALATION_TOOL" tar -xz -C /usr/local/bin
    else
        printf "%b\n" "${GREEN}Ngrok is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installNgrok