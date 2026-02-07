#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="ngrok"


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
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    if [ -x /usr/local/bin/ngrok ]; then
        "$ESCALATION_TOOL" rm -f /usr/local/bin/ngrok || true
    fi
    exit 0
fi


installNgrok
