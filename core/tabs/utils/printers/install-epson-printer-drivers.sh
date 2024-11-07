#!/bin/sh -e

. ../../common-script.sh
. ./install-cups.sh

installEpsonPrinterDriver() {
    clear

    case "$PACKAGER" in
    pacman)
        "$AUR_HELPER" -S --noconfirm epson-inkjet-printer-escpr
        ;;
    apt-get | nala)
        "$ESCALATION_TOOL" "$PACKAGER" install -y printer-driver-escpr
        ;;
    dnf)
        "$ESCALATION_TOOL" "$PACKAGER" install -y epson-inkjet-printer-escpr
        ;;
    *)
        printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
        exit 1
        ;;
    esac
}

checkEnv
checkEscalationTool
checkAURHelper
installCUPS
installEpsonPrinterDriver
