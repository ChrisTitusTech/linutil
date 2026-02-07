#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="lynx"


installLynx() {
    if ! command_exists lynx; then
        printf "%b\n" "${YELLOW}Installing Lynx...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lynx
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add lynx
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy lynx
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y lynx
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Lynx TUI Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installLynx
