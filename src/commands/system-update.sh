#!/bin/bash -e

. ./common-script.sh

checkEnv() {
    checkCommandRequirements 'curl groups sudo'
    checkPackageManager 'apt-get nala dnf pacman zypper yum'
    checkSuperUser
    checkDistro
}

fastUpdate() {
    case ${PACKAGER} in
        pacman)
            if ! command_exists yay && ! command_exists paru; then
                printf "Installing yay as AUR helper...\n"
                sudo ${PACKAGER} --noconfirm -S base-devel || { printf "${RED}Failed to install base-devel${RC}\n"; exit 1; }
                cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git
                cd yay-git && makepkg --noconfirm -si || { printf "${RED}Failed to install yay${RC}\n"; exit 1; }
            else
                printf "Aur helper already installed\n"
            fi
            if command_exists yay; then
                AUR_HELPER="yay"
            elif command_exists paru; then
                AUR_HELPER="paru"
            else
                printf "No AUR helper found. Please install yay or paru.\n"
                exit 1
            fi
            ${AUR_HELPER} --noconfirm -S rate-mirrors-bin
            sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
            
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
                sudo apt-get install -y nala || { printf "${YELLOW}Falling back to apt-get${RC}\n"; PACKAGER="apt-get"; }
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
            printf "${RED}Unsupported package manager: ${PACKAGER}${RC}\n"
            exit 1
            ;;
    esac
}

updateSystem() {
    printf "${GREEN}Updating system${RC}\n"
    case ${PACKAGER} in
        nala|apt-get)
            sudo "${PACKAGER}" update -y
            sudo "${PACKAGER}" upgrade -y
            ;;
        yum|dnf)
            sudo "${PACKAGER}" update -y
            sudo "${PACKAGER}" upgrade -y
            ;;
        pacman)
            sudo "${PACKAGER}" -Syu --noconfirm
            ;;
        zypper)
            sudo "${PACKAGER}" refresh
            sudo "${PACKAGER}" update -y
            ;;
        *)
            printf "${RED}Unsupported package manager: ${PACKAGER}${RC}\n"
            exit 1
            ;;
    esac
}

checkEnv
fastUpdate
updateSystem
