#!/bin/sh -e

. ../../common-script.sh
. ./install-cups.sh

installHpPrinterDriver() {
    clear

    case "$PACKAGER" in
    apt-get|dnf|eopkg|nala)
        "$ESCALATION_TOOL" "$PACKAGER" install -y hplip
        ;;
    pacman)
        "$ESCALATION_TOOL" -S --noconfirm --needed hplip-lite
        ;;
    xbps-install) 
        "$ESCALATION_TOOL" "$PACKAGER" -Sy hplip
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
installHpPrinterDriver