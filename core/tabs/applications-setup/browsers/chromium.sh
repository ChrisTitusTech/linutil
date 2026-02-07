#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="chromium"


installChromium() {
if ! command_exists chromium; then
    printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm chromium
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add chromium
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy chromium
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y chromium
            ;;
    esac
else
    printf "%b\n" "${GREEN}Chromium Browser is already installed.${RC}"
fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installChromium
