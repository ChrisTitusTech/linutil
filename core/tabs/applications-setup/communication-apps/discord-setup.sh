#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.discordapp.Discord"
APP_UNINSTALL_PKGS="Falling back discord to unavailable."


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
        if installDiscordNative; then
            return 0
        fi
        printf "%b\n" "${YELLOW}Native install unavailable. Falling back to Flatpak...${RC}"
        installDiscordFlatpak
    else
        printf "%b\n" "${GREEN}Discord is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installDiscord
