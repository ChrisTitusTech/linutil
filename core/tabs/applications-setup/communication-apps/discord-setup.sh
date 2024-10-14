#!/bin/sh -e

. ../../common-script.sh

installDiscord() {
    if ! command_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -Lo discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                elevated_execution "$PACKAGER" install -y discord.deb
                ;;
            zypper)
                elevated_execution "$PACKAGER" --non-interactive install discord
                ;;
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm discord 
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
                elevated_execution "$PACKAGER" install -y discord
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