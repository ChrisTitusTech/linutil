#!/bin/sh -e

. ../../common-script.sh

installNgrok() {
    if ! command_exists ngrok; then
        printf "%b\n" "${YELLOW}Installing Ngrok.${RC}"
        case "$ARCH" in
            x86_64)
                url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
                ;;
            aarch64)
                url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
                ;;
        esac
        curl -sSL "$url" -o ngrok.tgz
        "$ESCALATION_TOOL" tar -xzf ngrok.tgz -C /usr/local/bin
    else
        printf "%b\n" "${GREEN}Ngrok is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installNgrok
