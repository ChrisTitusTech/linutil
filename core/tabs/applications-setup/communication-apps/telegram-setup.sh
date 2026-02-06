#!/bin/sh -e

. ../../common-script.sh

installTelegram() {
    if ! flatpak_app_installed org.telegram.desktop && ! command_exists telegram-desktop; then
        printf "%b\n" "${YELLOW}Installing Telegram...${RC}"
        if try_flatpak_install org.telegram.desktop; then
            return 0
        fi
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm telegram-desktop 
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add telegram-desktop
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy telegram-desktop
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y telegram
                ;;
            *)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
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
