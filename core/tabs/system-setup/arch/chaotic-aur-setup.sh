#!/bin/sh -e

. ../../common-script.sh

installChaoticAUR() {
    case "$PACKAGER" in
        pacman)
            if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                printf "%b\n" "${YELLOW}Installing Chaotic-AUR repository...${RC}"
                curl -fsSL https://naturl.link/chaotic-aur | "$ESCALATION_TOOL" sh
                printf "%b\n" "${GREEN}Chaotic-AUR repository installed and enabled${RC}"
            else
                printf "%b\n" "${GREEN}Chaotic-AUR repository already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Chaotic-AUR is only supported on Arch-based systems${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installChaoticAUR