#!/bin/sh -e

. ../../common-script.sh

installThunderBird() {
    if ! command_exists thunderbird; then
        printf "%b\n" "${YELLOW}Installing Thunderbird...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm thunderbird
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add thunderbird
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy thunderbird
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y thunderbird 
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Thunderbird is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installThunderBird