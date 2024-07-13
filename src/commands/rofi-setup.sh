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

setupRofi() {
    echo "Install Rofi if not already installed..."
    if ! command_exists rofi; then
        case ${PACKAGER} in
            pacman)
                sudo ${PACKAGER} -S --noconfirm rofi
                ;;
            *)
                sudo ${PACKAGER} install -y rofi
                ;;
        esac
    else
        echo "Rofi is already installed."
    fi
    echo "Copy Rofi config files"
    if [ -d "${HOME}/.config/rofi" ]; then
        cp -r ${HOME}/.config/rofi ${HOME}/.config/rofi.bak
    fi
    mkdir -p ${HOME}/.config/rofi
    wget -O ${HOME}/.config/rofi/powermenu.sh https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/powermenu.sh
    chmod +x ${HOME}/.config/rofi/powermenu.sh
    wget -O ${HOME}/.config/rofi/config.rasi https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/config.rasi
    mkdir -p ${HOME}/.config/rofi/themes
    wget -O ${HOME}/.config/rofi/themes/nord.rasi https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/nord.rasi
    wget -O ${HOME}/.config/rofi/themes/sidetab-nord.rasi https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/sidetab-nord.rasi
    wget -O ${HOME}/.config/rofi/themes/powermenu.rasi https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/powermenu.rasi
}

checkEnv
setupRofi