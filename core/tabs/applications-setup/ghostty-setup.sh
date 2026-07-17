#!/bin/sh -e

. ../common-script.sh

installGhostty() {
    if ! command_exists ghostty; then
    printf "%b\n" "${YELLOW}Installing Ghostty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ghostty
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add ghostty
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy ghostty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ghostty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Ghostty is already installed.${RC}"
    fi
}

checkEnv
installGhostty
