#!/bin/sh -e

. ../../common-script.sh

# Function to install CUPS for printers
installCUPS() {
    clear

    case "$PACKAGER" in
    pacman)
        "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm cups
        ;;
    apt-get | nala)
        "$ESCALATION_TOOL" "$PACKAGER" install -y cups
        ;;
    dnf)
        "$ESCALATION_TOOL" "$PACKAGER" install -y cups
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
