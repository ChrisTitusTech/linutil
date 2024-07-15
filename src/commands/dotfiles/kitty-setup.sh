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
            echo "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
            exit 1
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='apt-get dnf pacman zypper'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo "Using ${pgm}"
            break
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep -q ${sug}; then
            SUGROUP=${sug}
            echo "Super user group ${SUGROUP}"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q ${SUGROUP}; then
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi

    DTYPE="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE=$ID
    fi
}

setupKitty() {
    echo "Install Kitty if not already installed..."
    if ! command_exists kitty; then
        case ${PACKAGER} in
            pacman)
                sudo ${PACKAGER} -S --noconfirm kitty
                ;;
            *)
                sudo ${PACKAGER} install -y kitty
                ;;
        esac
    else
        echo "Kitty is already installed."
    fi
    echo "Copy Kitty config files"
    if [ -d "${HOME}/.config/kitty" ]; then
        cp -r ${HOME}/.config/kitty ${HOME}/.config/kitty-bak
    fi
    mkdir -p ${HOME}/.config/kitty/
    wget -O ${HOME}/.config/kitty/kitty.conf https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    wget -O ${HOME}/.config/kitty/nord.conf https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
setupKitty