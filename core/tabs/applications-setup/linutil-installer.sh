#!/bin/sh -e

. ../common-script.sh

installLinutil() {
    printf "%b\n" "${YELLOW}Installing Linutil...${RC}"
    case "$PACKAGER" in
        pacman)
            printf "%b\n" "-----------------------------------------------------"
            printf "%b\n" "Select the package to install:"
            printf "%b\n" "1. ${CYAN}linutil${RC}      (stable release compiled from source)"
            printf "%b\n" "2. ${CYAN}linutil-bin${RC}  (stable release pre-compiled)"
            printf "%b\n" "3. ${CYAN}linutil-git${RC}  (compiled from the latest commit)"
            printf "%b\n" "-----------------------------------------------------"
            printf "%b" "Enter your choice: "
            read -r choice
            case $choice in
                1) "$AUR_HELPER" -S --noconfirm linutil ;;
                2) "$AUR_HELPER" -S --noconfirm linutil-bin ;;
                3) "$AUR_HELPER" -S --noconfirm linutil-git ;;
                *)
                    printf "%b\n" "${RED}Invalid choice:${RC} $choice"
                    exit 1
                    ;;
            esac
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
        *)
            printf "%b\n" "${RED}There are no official packages for your distro.${RC}"
            printf "%b" "${YELLOW}Do you want to install the crates.io package? (y/N) ${RC}"
            read -r choice
            case $choice in
                y|Y)
                    printf "%b\n" "Work In Progress."
                    ;;
                *) printf "%b\n" "${RED}Linutil not installed.${RC}" ;;
            esac
    esac
}

checkEnv
checkEscalationTool
checkAURHelper
installLinutil
