#!/bin/sh -e

. ../common-script.sh

removeSnaps() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Rns snapd
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" autoremove --purge snapd
            if [ "$ID" = ubuntu ]; then
                "$ESCALATION_TOOL" apt-mark hold snapd
            fi
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" remove snapd
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" remove snapd
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: "$PACKAGER"${RC}"
            exit 1
            ;;
    esac
}

checkEnv
checkEscalationTool
removeSnaps
