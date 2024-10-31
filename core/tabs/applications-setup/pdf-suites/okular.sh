#!/bin/sh -e

. ../../common-script.sh

installOkular() {
    if ! command_exists okular; then
        printf "%b\n" "${YELLOW}Installing Okular...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm okular
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add okular
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y okular
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Okular is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installOkular