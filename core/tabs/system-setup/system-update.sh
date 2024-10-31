#!/bin/sh -e

. ../common-script.sh

fastUpdate() {
    case "$PACKAGER" in
        pacman)

            $AUR_HELPER -S --needed --noconfirm rate-mirrors-bin

            printf "%b\n" "${YELLOW}Generating a new list of mirrors using rate-mirrors. This process may take a few seconds...${RC}"

            if [ -s /etc/pacman.d/mirrorlist ]; then
                "$ESCALATION_TOOL" cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
            fi

            # If for some reason DTYPE is still unknown use always arch so the rate-mirrors does not fail
            dtype_local=${DTYPE}
            if [ "${DTYPE}" = "unknown" ]; then
                dtype_local="arch"
            fi

            "$ESCALATION_TOOL" rate-mirrors --top-mirrors-number-to-retest=5 --disable-comments --save /etc/pacman.d/mirrorlist --allow-root ${dtype_local}
            if [ $? -ne 0 ] || [ ! -s /etc/pacman.d/mirrorlist ]; then
                printf "%b\n" "${RED}Rate-mirrors failed, restoring backup.${RC}"
                "$ESCALATION_TOOL" cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
            fi
            ;;

        apt-get|nala)
            "$ESCALATION_TOOL" apt-get update
            if ! command_exists nala; then
                "$ESCALATION_TOOL" apt-get install -y nala || { printf "%b\n" "${YELLOW}Falling back to apt-get${RC}"; PACKAGER="apt-get"; }
            fi

            if [ "$PACKAGER" = "nala" ]; then
                "$ESCALATION_TOOL" cp /etc/apt/sources.list /etc/apt/sources.list.bak
                "$ESCALATION_TOOL" nala update
                PACKAGER="nala"
            fi

            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" update -y
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" ref
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive dup
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: "$PACKAGER"${RC}"
            exit 1
            ;;
    esac
}

updateSystem() {
    printf "%b\n" "${GREEN}Updating system${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" update -y
            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy --noconfirm --needed archlinux-keyring
            "$ESCALATION_TOOL" "$PACKAGER" -Su --noconfirm
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" ref
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive dup
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: "$PACKAGER"${RC}"
            exit 1
            ;;
    esac
}

updateFlatpaks() {
    if command_exists flatpak; then
        printf "%b\n" "${YELLOW}Updating installed Flathub apps...${RC}"
        installed_apps=$(flatpak list --app --columns=application)

        if [ -z "$installed_apps" ]; then
            printf "%b\n" "${RED}No Flathub apps are installed.${RC}"
            return
        fi

        for app in $installed_apps; do
            printf "%b\n" "${YELLOW}Updating $app...${RC}"
            flatpak update -y "$app"
        done
    fi
}

checkEnv
checkAURHelper
checkEscalationTool
fastUpdate
updateSystem
updateFlatpaks
