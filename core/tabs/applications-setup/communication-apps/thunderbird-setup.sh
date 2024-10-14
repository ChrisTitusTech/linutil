#!/bin/sh -e

. ../../common-script.sh

installThunderBird() {
    if ! command_exists thunderbird; then
        printf "%b\n" "${YELLOW}Installing Thunderbird...${RC}"
        case "$PACKAGER" in
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm thunderbird
                ;;
            *)
                elevated_execution "$PACKAGER" install -y thunderbird 
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Thunderbird is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installThunderBird