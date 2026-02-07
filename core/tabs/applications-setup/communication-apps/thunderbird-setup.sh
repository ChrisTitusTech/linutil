#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.mozilla.Thunderbird"
APP_UNINSTALL_PKGS="thunderbird"


installThunderBird() {
    if ! flatpak_app_installed org.mozilla.Thunderbird && ! command_exists thunderbird; then
        printf "%b\n" "${YELLOW}Installing Thunderbird...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm thunderbird
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add thunderbird
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy thunderbird
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y thunderbird
                ;;
        esac
        if command_exists thunderbird; then
            return 0
        fi
        if try_flatpak_install org.mozilla.Thunderbird; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Thunderbird is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installThunderBird
