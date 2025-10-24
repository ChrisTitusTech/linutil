#!/bin/sh -e

. ../common-script.sh

fastUpdate() {
    case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm rate-mirrors-bin

            printf "%b\n" "${YELLOW}Generating a new list of mirrors using rate-mirrors. This process may take a few seconds...${RC}"

            if [ -s "/etc/pacman.d/mirrorlist" ]; then
                "$ESCALATION_TOOL" cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
            fi

            # If for some reason DTYPE is still unknown use always arch so the rate-mirrors does not fail
            dtype_local="$DTYPE"
            if [ "$dtype_local" = "unknown" ]; then
                dtype_local="arch"
            fi

            if ! "$ESCALATION_TOOL" rate-mirrors --top-mirrors-number-to-retest=5 --disable-comments --save /etc/pacman.d/mirrorlist --allow-root "$dtype_local" > /dev/null || [ ! -s "/etc/pacman.d/mirrorlist" ]; then
                printf "%b\n" "${RED}Rate-mirrors failed, restoring backup.${RC}"
                "$ESCALATION_TOOL" cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
            fi
            ;;
        apt-get|nala)
            if [ "$PACKAGER" = "apt-get" ]; then
                printf "%b\n" "${YELLOW}Installing nala for faster updates.${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" update
                if "$ESCALATION_TOOL" "$PACKAGER" install -y nala; then
                    PACKAGER="nala";
                    printf "%b\n" "${CYAN}Using $PACKAGER as package manager${RC}"
                else
                    printf "%b\n" "${RED}Nala installation failed.${RC}"
                    printf "%b\n" "${YELLOW}Falling back to apt-get.${RC}"
                fi
            fi

            if [ "$PACKAGER" = "nala" ]; then
                if [ -f "/etc/apt/sources.list.d/nala-sources.list" ]; then
                    "$ESCALATION_TOOL" cp /etc/apt/sources.list.d/nala-sources.list /etc/apt/sources.list.d/nala-sources.list.bak
                fi
                if [ -f "/etc/apt/sources.list.d/fetch.sources" ]; then
                    "$ESCALATION_TOOL" cp /etc/apt/sources.list.d/fetch.sources /etc/apt/sources.list.d/fetch.sources.bak
                fi

                if ! "$ESCALATION_TOOL" nala fetch --auto -y; then
                    printf "%b\n" "${RED}Nala fetch failed, restoring backup.${RC}"
                    if [ -f "/etc/apt/sources.list.d/nala-sources.list.bak" ]; then
                        "$ESCALATION_TOOL" cp /etc/apt/sources.list.d/nala-sources.list.bak /etc/apt/sources.list.d/nala-sources.list
                    fi
                    if [ -f "/etc/apt/sources.list.d/fetch.sources.bak" ]; then
                        "$ESCALATION_TOOL" cp /etc/apt/sources.list.d/fetch.sources.bak /etc/apt/sources.list.d/fetch.sources
                    fi
                fi
            fi
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" update -y
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" ref
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" update
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -S
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" -y update-repo
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

updateSystem() {
    printf "%b\n" "${YELLOW}Updating system packages.${RC}"
    case "$PACKAGER" in
        apt-get|nala|dnf|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy --noconfirm --needed archlinux-keyring
            "$AUR_HELPER" -Su --noconfirm
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive dup
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -yu
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

updateFlatpaks() {
    if command_exists flatpak; then
        printf "%b\n" "${YELLOW}Updating flatpak packages.${RC}"
        flatpak update -y
    fi
}

checkEnv
checkAURHelper
checkEscalationTool
fastUpdate
updateSystem
updateFlatpaks
