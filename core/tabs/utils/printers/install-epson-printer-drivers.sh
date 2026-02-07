#!/bin/sh -e

. ../../common-script.sh
. ./install-cups.sh

LINUTIL_UNINSTALL_SUPPORTED=1

installEpsonPrinterDriver() {
    clear

    case "$PACKAGER" in
    pacman)
        "$AUR_HELPER" -S --noconfirm epson-inkjet-printer-escpr
        ;;
    apt-get|nala)
        "$ESCALATION_TOOL" "$PACKAGER" install -y printer-driver-escpr
        ;;
    dnf|eopkg)
        "$ESCALATION_TOOL" "$PACKAGER" install -y epson-inkjet-printer-escpr
        ;;
    xbps-install) 
        "$ESCALATION_TOOL" "$PACKAGER" -Sy epson-inkjet-printer-escpr
        ;;
    *)
        printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
        exit 1
        ;;
    esac
}

uninstallEpsonPrinterDriver() {
    printf "%b\n" "${YELLOW}Uninstalling Epson printer drivers...${RC}"
    uninstall_native epson-inkjet-printer-escpr || true
    uninstall_native printer-driver-escpr || true
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallEpsonPrinterDriver
else
    installCUPS
    installEpsonPrinterDriver
fi
