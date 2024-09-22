#!/bin/sh -e

. ../../common-script.sh

installTelegram() {
    if ! command_exists telegram-desktop; then
        printf "%b\n" "${YELLOW}Installing Telegram...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" -y install telegram-desktop
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install telegram-desktop
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm telegram-desktop 
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y telegram-desktop 
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Telegram is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installTelegram