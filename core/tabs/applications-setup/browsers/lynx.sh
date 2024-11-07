#!/bin/sh -e

. ../../common-script.sh

installLynx() {
    if ! command_exists lynx; then
        printf "%b\n" "${YELLOW}Installing Lynx...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lynx
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add lynx
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y lynx
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Lynx TUI Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installLynx