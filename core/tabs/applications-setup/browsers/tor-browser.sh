#!/bin/sh -e

. ../../common-script.sh

installTorBrowser() {
    if ! command_exists torbrowser-launcher; then
        printf "%b\n" "${YELLOW}Installing Tor Browser...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y torbrowser-launcher
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install torbrowser-launcher
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm torbrowser-launcher
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y torbrowser-launcher
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Tor Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installTorBrowser

