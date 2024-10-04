#!/bin/sh -e

. ../common-script.sh

removeSnaps() {
    if command_exists snap; then
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
            dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove snapd
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
        printf "%b\n" "${GREEN}Successfully removed snaps.${RC}"
    else
        printf "%b\n" "${GREEN}Snapd is not installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
removeSnaps
