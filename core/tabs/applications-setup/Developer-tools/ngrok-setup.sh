#!/bin/sh -e

. ../../common-script.sh

installNgrok() {
    if ! command_exists ngrok; then
        printf "%b\n" "${YELLOW}Installing Ngrok...${RC}"
        curl -sSLO https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
        if [ -f "ngrok-v3-stable-linux-amd64.tgz" ]; then
            elevated_execution tar -xz -f ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin
        else
            printf "%b\n" "${RED}Error occurred when downloading.${RC}"
            exit 1
        fi
    else
        printf "%b\n" "${GREEN}Ngrok is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installNgrok
