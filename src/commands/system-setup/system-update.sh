#!/bin/sh -e

. ../common-script.sh

fastUpdate() {
    case ${PACKAGER} in
        pacman)
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                $ESCALATION_TOOL ${PACKAGER} -S --needed --noconfirm base-devel || { echo -e "${RED}Failed to install base-devel${RC}"; exit 1; }
                cd /opt && $ESCALATION_TOOL git clone https://aur.archlinux.org/yay-git.git && $ESCALATION_TOOL chown -R ${USER}:${USER} ./yay-git
                cd yay-git && makepkg --noconfirm -si || { echo -e "${RED}Failed to install yay${RC}"; exit 1; }
            else
                echo "AUR helper already installed"
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
                $ESCALATION_TOOL cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
            fi

            # If for some reason DTYPE is still unknown use always arch so the rate-mirrors does not fail
            dtype_local=${DTYPE}
            if [ "${DTYPE}" = "unknown" ]; then
                dtype_local="arch"
            fi

            $ESCALATION_TOOL rate-mirrors --top-mirrors-number-to-retest=5 --disable-comments --save /etc/pacman.d/mirrorlist --allow-root ${dtype_local}
            if [ $? -ne 0 ] || [ ! -s /etc/pacman.d/mirrorlist ]; then
                echo -e "${RED}Rate-mirrors failed, restoring backup.${RC}"
                $ESCALATION_TOOL cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
            fi
            ;;

        apt-get|nala)
            $ESCALATION_TOOL apt-get update
            if ! command_exists nala; then
                $ESCALATION_TOOL apt-get install -y nala || { echo -e "${YELLOW}Falling back to apt-get${RC}"; PACKAGER="apt-get"; }
            fi

            if [ "${PACKAGER}" = "nala" ]; then
                $ESCALATION_TOOL cp /etc/apt/sources.list /etc/apt/sources.list.bak
                $ESCALATION_TOOL nala update
                PACKAGER="nala"
            fi

            $ESCALATION_TOOL ${PACKAGER} upgrade -y
            ;;
        dnf)
            $ESCALATION_TOOL ${PACKAGER} update -y
            ;;
        zypper)
            $ESCALATION_TOOL ${PACKAGER} ref
            $ESCALATION_TOOL ${PACKAGER} --non-interactive dup
            ;;
        yum)
            $ESCALATION_TOOL ${PACKAGER} update -y
            $ESCALATION_TOOL ${PACKAGER} upgrade -y
            ;;
        xbps-install)
            $ESCALATION_TOOL ${PACKAGER} -Syu
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
            $ESCALATION_TOOL "${PACKAGER}" update -y
            $ESCALATION_TOOL "${PACKAGER}" upgrade -y
            ;;
        yum|dnf)
            $ESCALATION_TOOL "${PACKAGER}" update -y
            $ESCALATION_TOOL "${PACKAGER}" upgrade -y
            ;;
        pacman)
            $ESCALATION_TOOL "${PACKAGER}" -Sy --noconfirm --needed archlinux-keyring
            $ESCALATION_TOOL "${PACKAGER}" -Su --noconfirm
            ;;
        zypper)
            $ESCALATION_TOOL ${PACKAGER} ref
            $ESCALATION_TOOL ${PACKAGER} --non-interactive dup
            ;;
        xbps-install)
            $ESCALATION_TOOL ${PACKAGER} -Syu
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
checkEscalationTool
fastUpdate
updateSystem
updateFlatpaks
