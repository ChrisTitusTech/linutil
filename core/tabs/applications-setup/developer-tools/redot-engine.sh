#!/bin/sh -e

. ../../common-script.sh

install_redot_engine() {
    if ! command_exists redot-mono; then
        printf "%b\n" "${YELLOW}Installing Redot Engine...${RC}"
        case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm redot-mono-bin
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
        esac
    else
        printf "%b\n" "${GREEN} Redot Engine Is Already Installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
install_redot_engine