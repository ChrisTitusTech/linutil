#!/bin/sh -e

. ../../common-script.sh

if ! command_exists chromium; then
    printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm chromium
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y chromium
            ;;
    esac
else
    printf "%b\n" "${GREEN}Chromium Browser is already installed.${RC}"
fi

checkEnv
checkEscalationTool
