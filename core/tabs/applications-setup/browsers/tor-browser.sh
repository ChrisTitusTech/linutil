#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="torbrowser-launcher"


installTorBrowser() {
    if ! command_exists torbrowser-launcher; then
        printf "%b\n" "${YELLOW}Installing Tor Browser...${RC}"
        case "$PACKAGER" in
            apt-get|nala|dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y torbrowser-launcher
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install torbrowser-launcher
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm torbrowser-launcher
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy torbrowser-launcher
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
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installTorBrowser

