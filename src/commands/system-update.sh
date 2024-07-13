#!/bin/bash

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'

command_exists() {
    command -v $1 >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    if ! command_exists ${REQUIREMENTS}; then
        echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
        exit 1
    fi

    ## Check Package Handeler
    PACKAGEMANAGER='apt-get dnf pacman zypper'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo -e "Using ${pgm}"
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep ${sug}; then
            SUGROUP=${sug}
            echo -e "Super user group ${SUGROUP}"
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep ${SUGROUP} >/dev/null; then
        echo -e "${RED}You need to be a member of the sudo group to run me!"
        exit 1
    fi


    DTYPE="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -f /etc/os-release ]; then
            source /etc/os-release
            DTYPE=$ID
    fi

}

fastUpdate() {
    case ${PACKAGER} in
        pacman)
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                sudo ${PACKAGER} --noconfirm -S base-devel
                cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git
                cd yay-git && makepkg --noconfirm -si
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
            sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
            
            # If for some reason DTYPE is still unknown use always arch so the rate-mirrors does not fail
            local dtype_local=${DTYPE}
            if [ ${DTYPE} == "unknown" ]; then
                dtype_local="arch"
            fi
            sudo rate-mirrors --top-mirrors-number-to-retest=5 --disable-comments --save /etc/pacman.d/mirrorlist --allow-root ${dtype_local}
            ;;
        apt-get|nala)
            sudo apt-get update
            sudo apt-get install -y nala
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            sudo nala update
            PACKAGER="nala"
            sudo ${PACKAGER} upgrade -y
            ;;
        dnf)
            ;;
        zypper)
            ;;
        *)
            echo -e "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

updateSystem() {
    echo -e "${GREEN}Updating system${RC}"
    case ${PACKAGER} in
        nala)
            sudo ${PACKAGER} update -y
            sudo ${PACKAGER} upgrade -y
            ;;
        yum)
            sudo ${PACKAGER} update -y
            sudo ${PACKAGER} upgrade -y
            ;;
        dnf)
            sudo ${PACKAGER} update -y
            sudo ${PACKAGER} upgrade -y
            ;;
        pacman)
            sudo ${PACKAGER} -Syu --noconfirm
            ;;
        zypper)
            sudo ${PACKAGER} refresh
            sudo ${PACKAGER} update -y
            ;;
        *)
            echo -e "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

checkEnv
fastUpdate
updateSystem
