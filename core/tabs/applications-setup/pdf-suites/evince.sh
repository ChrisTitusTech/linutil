#!/bin/sh -e

. ../../common-script.sh

installEvince() {
    if ! command_exists evince; then
        printf "%b\n" "${YELLOW}Installing Evince...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm evince
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add evince
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y evince
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Evince is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installEvince