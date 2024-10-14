#!/bin/sh -e

. ../../common-script.sh

installDepend() {
    case "$PACKAGER" in
        pacman)
            if ! command_exists paru; then
                printf "%b\n" "${YELLOW}Installing paru as AUR helper...${RC}"
                elevated_execution "$PACKAGER" -S --needed --noconfirm base-devel git
                cd /opt && elevated_execution git clone https://aur.archlinux.org/paru.git && elevated_execution chown -R "$USER": ./paru
                cd paru && makepkg --noconfirm -si
                printf "%b\n" "${GREEN}Paru installed${RC}"
            else
                printf "%b\n" "${GREEN}Paru already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installDepend
