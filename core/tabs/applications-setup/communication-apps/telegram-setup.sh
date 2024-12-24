#!/bin/sh -e

. ../../common-script.sh

installTelegram() {
    if ! command_exists telegram-desktop; then
        printf "%b\n" "${YELLOW}Installing Telegram...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm telegram-desktop 
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add telegram-desktop
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -y telegram-desktop
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" -y install telegram
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y telegram-desktop 
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Telegram is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installTelegram