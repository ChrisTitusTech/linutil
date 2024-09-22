#!/bin/sh -e

. ../../common-script.sh

installThunderBird() {
    if ! command_exists thunderbird; then
        printf "%b\n" "${YELLOW}Installing Thunderbird...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" -y install thunderbird
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install thunderbird
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm thunderbird
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y thunderbird 
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Thunderbird is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installThunderBird