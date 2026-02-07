#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="okular"


installOkular() {
    if ! command_exists okular; then
        printf "%b\n" "${YELLOW}Installing Okular...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm okular
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add okular
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy okular
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y okular
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Okular is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installOkular
