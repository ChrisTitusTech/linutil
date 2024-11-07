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