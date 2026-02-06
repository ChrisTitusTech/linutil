#!/bin/sh -e

. ../../common-script.sh

installDiscordFlatpak() {
    try_flatpak_install com.discordapp.Discord || return 1
}

installDiscordNative() {
    case "$PACKAGER" in
        zypper|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y discord
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm discord
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
            "$ESCALATION_TOOL" "$PACKAGER" install -y discord
            ;;
        *)
            return 1
            ;;
    esac
}

installDiscord() {
    if ! command_exists com.discordapp.Discord && ! command_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                installDiscordFlatpak
                ;;
            zypper|eopkg)
                if ! installDiscordFlatpak; then
                    printf "%b\n" "${YELLOW}Flatpak install failed, falling back to native package...${RC}"
                    installDiscordNative
                fi
                ;;
            pacman)
                if ! installDiscordFlatpak; then
                    printf "%b\n" "${YELLOW}Flatpak install failed, falling back to native package...${RC}"
                    installDiscordNative
                fi
                ;;
            dnf)
                if ! installDiscordFlatpak; then
                    printf "%b\n" "${YELLOW}Flatpak install failed, falling back to native package...${RC}"
                    installDiscordNative
                fi
                ;;
            apk | xbps-install)
                installDiscordFlatpak
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Discord is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installDiscord
