#!/bin/sh -e

. ../../common-script.sh

installSlack() {
    if ! flatpak_app_installed com.slack.Slack && ! command_exists slack; then
        printf "%b\n" "${YELLOW}Installing Slack...${RC}"
        if try_flatpak_install com.slack.Slack; then
            return 0
        fi
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm slack-desktop
                ;;
            *)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Slack is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installSlack
