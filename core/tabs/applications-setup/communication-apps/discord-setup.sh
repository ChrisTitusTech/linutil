#!/bin/sh -e

. ../../common-script.sh

installDiscord() {
    if ! command_exists com.discordapp.Discord && ! command_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -Lo discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                "$ESCALATION_TOOL" "$PACKAGER" install -y discord.deb
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install discord
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm discord 
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
                "$ESCALATION_TOOL" "$PACKAGER" install -y discord
                ;;
            apk)
                checkFlatpak
                flatpak install -y flathub com.discordapp.Discord
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