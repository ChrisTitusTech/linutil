#!/bin/sh -e

. ../common-script.sh

fastUpdate() {
    case ${PACKAGER} in
        pacman)
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                sudo ${PACKAGER} -S --needed --noconfirm base-devel || { echo -e "${RED}Failed to install base-devel${RC}"; exit 1; }
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
            ${AUR_HELPER} -S --needed --noconfirm rate-mirrors-bin
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
            sudo ${PACKAGER} ref
            sudo ${PACKAGER} --non-interactive dup
            ;;
        yum)
            sudo ${PACKAGER} update -y
            sudo ${PACKAGER} upgrade -y
            ;;
        xbps-install)
            sudo ${PACKAGER} -Syu
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
            sudo "${PACKAGER}" update -y
            sudo "${PACKAGER}" upgrade -y
            ;;
        yum|dnf)
            sudo "${PACKAGER}" update -y
            sudo "${PACKAGER}" upgrade -y
            ;;
        pacman)
            sudo "${PACKAGER}" -Sy --noconfirm --needed archlinux-keyring
            sudo "${PACKAGER}" -Su --noconfirm
            ;;
        zypper)
            sudo ${PACKAGER} ref
            sudo ${PACKAGER} --non-interactive dup
            ;;
        xbps-install)
            sudo ${PACKAGER} -Syu
            ;;
        *)
            echo -e "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

updateFlatpaks() {
    if command_exists flatpak; then
        flatpak update -y
    fi
}

checkEnv
fastUpdate
updateSystem
updateFlatpaks
