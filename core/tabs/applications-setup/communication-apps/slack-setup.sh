#!/bin/sh -e

. ../../common-script.sh

checkSlackInstallation() {
    case "$PACKAGER" in
        pacman)
            command_exists slack
            ;;
        *)
            checkFlatpak
            flatpak_app_exists com.slack.Slack
            ;;
    esac
}

installSlack() {
    if ! checkSlackInstallation; then
        printf "%b\n" "${YELLOW}Installing Slack...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm slack-desktop
                ;;
            *)  
                flatpak install -y flathub com.slack.Slack
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