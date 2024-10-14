#!/bin/sh -e

. ../../common-script.sh

installFirefox() {
    if ! command_exists firefox; then
        printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                elevated_execution "$PACKAGER" install -y firefox-esr
                ;;
            zypper)
                elevated_execution "$PACKAGER" --non-interactive install MozillaFirefox
                ;;
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm firefox
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y firefox
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Firefox Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installFirefox
