#!/bin/sh -e

. ../../common-script.sh

installDepend() {
    case "$PACKAGER" in
        pacman)
            if ! command_exists yay; then
                printf "%b\n" "${YELLOW}Installing yay as AUR helper...${RC}"
                elevated_execution "$PACKAGER" -S --needed --noconfirm base-devel git
                cd /opt && elevated_execution git clone https://aur.archlinux.org/yay-bin.git && elevated_execution chown -R "$USER": ./yay-bin
                cd yay-bin && makepkg --noconfirm -si
                printf "%b\n" "${GREEN}Yay installed${RC}"
            else
                printf "%b\n" "${GREEN}Aur helper already installed${RC}"
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
