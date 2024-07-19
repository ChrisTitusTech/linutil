#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which $1 >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    for req in ${REQUIREMENTS}; do
        if ! command_exists ${req}; then
            echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
            exit 1
        fi
    done
    ## Check Package Handler
    PACKAGEMANAGER='apt-get nala dnf pacman zypper yum'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo "Using ${pgm}"
            break
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep ${sug} >/dev/null; then
            SUGROUP=${sug}
            echo "Super user group ${SUGROUP}"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep ${SUGROUP} >/dev/null; then
        echo -e "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi

    DTYPE="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE=$ID
    fi
}

fastUpdate() {
    case ${PACKAGER} in
        pacman)
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                sudo ${PACKAGER} --noconfirm -S base-devel || { echo -e "${RED}Failed to install base-devel${RC}"; exit 1; }
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
            dtype_local=${DTYPE}
            if [ "${DTYPE}" = "unknown" ]; then
                dtype_local="arch"
            fi
            sudo rate-mirrors --top-mirrors-number-to-retest=5 --disable-comments --save /etc/pacman.d/mirrorlist --allow-root ${dtype_local}
            ;;
        apt-get|nala)
            sudo apt-get update
            if ! command_exists nala; then
                sudo apt-get install -y nala || { echo -e "${YELLOW}Falling back to apt-get${RC}"; PACKAGER="apt-get"; }
            fi
            if [ "${PACKAGER}" = "nala" ]; then
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo nala update
                PACKAGER="nala"
            fi
            sudo ${PACKAGER} upgrade -y
            ;;
        dnf)
            sudo ${PACKAGER} update -y
            ;;
        zypper)
            sudo ${PACKAGER} refresh
            sudo ${PACKAGER} update -y
            ;;
        yum)
            sudo ${PACKAGER} update -y
            sudo ${PACKAGER} upgrade -y
            ;;
        *)
            echo -e "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
}

updateSystem() {
    echo -e "${GREEN}Updating system${RC}"
    case ${PACKAGER} in
        nala|apt-get)
            sudo ${PACKAGER} update -y
            sudo ${PACKAGER} upgrade -y
            ;;
        yum|dnf)
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