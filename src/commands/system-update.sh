#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which $1 >/dev/null 2>&1
}

fastUpdate() {
    case ${PKGR} in
        pacman)
            if ! command_exists yay && ! command_exists paru; then
                printf "Installing yay as AUR helper...\n"
                sudo ${PKGR} --noconfirm -S base-devel || { printf "${RED}Failed to install base-devel${RC}\n"; exit 1; }
                cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git
                cd yay-git && makepkg --noconfirm -si || { echo -e "${RED}Failed to install yay${RC}"; exit 1; }
            else
                echo "Aur helper already installed"
            fi
            if command_exists yay; then
                AUR_HELPER="yay"
            elif command_exists paru; then
                AUR_HELPER="paru"
            else
                echo "No AUR helper found. Please install yay or paru."
                exit 1
            fi
            ${AUR_HELPER} --noconfirm -S rate-mirrors-bin
            if [ -s /etc/pacman.d/mirrorlist ]; then
                sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
            fi
            
            # If for some reason DTYPE is still unknown use always arch so the rate-mirrors does not fail
            dtype_local=${DT}
            if [ "${DT}" = "unknown" ]; then
                dtype_local="arch"
            fi
            sudo rate-mirrors --top-mirrors-number-to-retest=5 --disable-comments --save /etc/pacman.d/mirrorlist --allow-root ${dtype_local}
            ;;
        apt-get|nala)
            sudo apt-get update
            if ! command_exists nala; then
                sudo apt-get install -y nala || { printf "${YELLOW}Falling back to apt-get${RC}\n"; PKGR="apt-get"; }
            fi
            if [ "${PKGR}" = "nala" ]; then
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo nala update
                PKGR="nala"
            fi
            sudo ${PKGR} upgrade -y
            ;;
        dnf)
            sudo ${PKGR} update -y
            ;;
        zypper)
            sudo ${PKGR} ref
            sudo ${PKGR} --non-interactive dup
            ;;
        yum)
            sudo ${PKGR} update -y
            sudo ${PKGR} upgrade -y
            ;;
        xbps-install)
            sudo ${PACKAGER} -Syu
            ;;
        *)
            printf "${RED}Unsupported package manager: ${PKGR}${RC}\n"
            exit 1
            ;;
    esac
}

updateSystem() {
    printf "${GREEN}Updating system${RC}\n"
    case ${PKGR} in
        nala|apt-get)
            sudo ${PKGR} update -y
            sudo ${PKGR} upgrade -y
            ;;
        yum|dnf)
            sudo ${PKGR} update -y
            sudo ${PKGR} upgrade -y
            ;;
        pacman)
            sudo ${PKGR} -Syu --noconfirm
            ;;
        zypper)
            sudo ${PKGR} ref
            sudo ${PKGR} --non-interactive dup
            ;;
        xbps-install)
            sudo ${PKGR} -Syu
            ;;
        *)
            echo -e "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

fastUpdate
updateSystem
