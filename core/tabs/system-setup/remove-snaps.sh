#!/bin/sh -e

. ../common-script.sh

removeSnaps() {
    if command_exists snap; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -Rns snapd --noconfirm
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" remove --purge -y snapd
                "$ESCALATION_TOOL" "$PACKAGER" autoremove -y
                if [ "$ID" = ubuntu ]; then
                    "$ESCALATION_TOOL" apt-mark hold snapd
                fi
                ;;
            dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y snapd
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
