#!/bin/sh -e

. ../../common-script.sh

# Function to install drivers for Epson printers
installEpsonPrinterDriver() {
    clear

    case "$PACKAGER" in
    pacman)
        "${AUR_HELPER}" -S --noconfirm epson-inkjet-printer-escpr
        ;;
    apt-get | nala)
        "$ESCALATION_TOOL" "${PACKAGER}" install -y printer-driver-escpr
        ;;
    dnf)
        "$ESCALATION_TOOL" "${PACKAGER}" install -y epson-inkjet-printer-escpr
        ;;
    *) ;;
    esac
}

checkEnv
checkEscalationTool
checkAURHelper
installEpsonPrinterDriver
