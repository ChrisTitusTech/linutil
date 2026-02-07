#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1

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

uninstallCUPS() {
    printf "%b\n" "${YELLOW}Uninstalling CUPS...${RC}"
    uninstall_native cups || true
}

if [ "${0##*/}" = "install-cups.sh" ]; then
    checkEnv
    checkEscalationTool
    if [ "$LINUTIL_ACTION" = "uninstall" ]; then
        uninstallCUPS
    else
        installCUPS
    fi
fi
