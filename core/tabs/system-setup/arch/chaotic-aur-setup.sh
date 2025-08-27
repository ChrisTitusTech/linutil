#!/bin/sh -e

. ../../common-script.sh

installChaoticAUR() {
    case "$PACKAGER" in
        pacman)
        # Check if Chaotic-AUR is already installed
            if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                # Print message indicating Chaotic-AUR is being installed
                printf "%b\n" "${YELLOW}Installing Chaotic-AUR repository...${RC}"
                # Call Escalation Tool and install and enable Chaotic-AUR
                curl -fsSL https://naturl.link/chaotic-aur | "$ESCALATION_TOOL" sh
                # Print message indicating Chaotic-AUR has been installed and enabled
                printf "%b\n" "${GREEN}Chaotic-AUR repository installed and enabled${RC}"
            else
                # Print message indicating Chaotic-AUR is already installed
                printf "%b\n" "${GREEN}Chaotic-AUR repository already installed${RC}"
            fi
            ;;
        *)  # Print error message when linutil detects that user is not on Arch-based system
            printf "%b\n" "${RED}Chaotic-AUR is only supported on Arch-based systems${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installChaoticAUR