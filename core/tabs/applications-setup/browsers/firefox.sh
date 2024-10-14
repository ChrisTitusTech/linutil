#!/bin/sh -e

. ../../common-script.sh

installFirefox() {
    if ! command_exists firefox; then
        printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y firefox-esr
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install MozillaFirefox
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm firefox
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y firefox
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add firefox
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
