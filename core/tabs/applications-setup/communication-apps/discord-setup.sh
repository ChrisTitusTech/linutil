#!/bin/sh -e

. ../../common-script.sh

installDiscord() {
    if ! command_exists com.discordapp.Discord && ! command_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -Lo discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./discord.deb
                "$ESCALATION_TOOL" rm discord.deb
                ;;
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
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub com.discordapp.Discord
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Discord is already installed.${RC}"
    fi
}

checkEnv
installDiscord
