#!/bin/sh -e

. ../../common-script.sh

installCUPS() {
    clear

    case "$PACKAGER" in
    pacman)
        "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm cups
        ;;
    apt-get|nala|dnf|eopkg)
        "$ESCALATION_TOOL" "$PACKAGER" install -y cups
        ;;
    xbps-install)
        "$ESCALATION_TOOL" "$PACKAGER" -Sy cups
        ;;
    *)
        printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
        exit 1
        ;;
    esac
}

checkEnv
checkEscalationTool
installCUPS
