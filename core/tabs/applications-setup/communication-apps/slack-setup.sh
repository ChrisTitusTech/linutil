#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.slack.Slack"
APP_UNINSTALL_PKGS=""


installSlack() {
    if ! flatpak_app_installed com.slack.Slack && ! command_exists slack; then
        printf "%b\n" "${YELLOW}Installing Slack...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm slack-desktop
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists slack; then
            return 0
        fi
        if try_flatpak_install com.slack.Slack; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Slack is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installSlack
