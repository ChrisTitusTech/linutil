#!/bin/sh -e

. ../../common-script.sh

installWaterfox() {
    buildWaterfox=$(curl -L -o waterfox.tar.bz2 "https://cdn1.waterfox.net/waterfox/releases/latest/linux" && tar -xvjf waterfox.tar.bz2 -C ./ && rm waterfox.tar.bz2 ; sudo mkdir -p /opt/waterfox && sudo mv waterfox /opt/waterfox && cd /opt/waterfox/waterfox && sudo ln -s /opt/waterfox/waterfox/waterfox /usr/bin/waterfox)

    if ! command_exists waterfox; then
        printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm curl && printf "$buildWaterfox"
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Waterfox is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installWaterfox
