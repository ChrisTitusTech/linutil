#!/bin/sh -e

. ../common-script.sh

checkGpu() {
    if lspci | grep -i nvidia > /dev/null; then
        printf "%b\n" "${RED}Waydroid is not compatible with NVIDIA GPUs.${RC}"
        exit 1
    fi
}

installWaydroid() {
    if ! command_exists waydroid; then
    printf "%b\n" "${YELLOW}Installing Waydroid...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm waydroid
                if command_exists dkms; then
                    "$AUR_HELPER" -S --needed --noconfirm binder_linux-dkms
                    elevated_execution modprobe binder-linux device=binder,hwbinder,vndbinder
                fi
                ;;
            apt-get|nala)
                curl https://repo.waydro.id | elevated_execution sh
                elevated_execution "$PACKAGER" install -y waydroid
                if command_exists dkms; then
                    elevated_execution "$PACKAGER" install -y git
                    mkdir -p "$HOME/.local/share/" # only create it if it doesnt exist
                    git clone https://github.com/choff/anbox-modules.git "$HOME/.local/share/anbox-modules"
                    cd "$HOME/.local/share/anbox-modules"
                    elevated_execution cp anbox.conf /etc/modules-load.d/
                    elevated_execution cp 99-anbox.rules /lib/udev/rules.d/
                    elevated_execution cp -rT ashmem /usr/src/anbox-ashmem-1
                    elevated_execution cp -rT binder /usr/src/anbox-binder-1
                    elevated_execution dkms install anbox-ashmem/1
                    elevated_execution dkms install anbox-binder/1
                fi
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y waydroid
                if command_exists dkms; then
                    elevated_execution "$PACKAGER" install -y git
                    mkdir -p "$HOME/.local/share/" # only create it if it doesnt exist
                    git clone https://github.com/choff/anbox-modules.git "$HOME/.local/share/anbox-modules"
                    cd "$HOME/.local/share/anbox-modules"
                    elevated_execution cp anbox.conf /etc/modules-load.d/
                    elevated_execution cp 99-anbox.rules /lib/udev/rules.d/
                    elevated_execution cp -rT ashmem /usr/src/anbox-ashmem-1
                    elevated_execution cp -rT binder /usr/src/anbox-binder-1
                    elevated_execution dkms install anbox-ashmem/1
                    elevated_execution dkms install anbox-binder/1
                fi
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Waydroid is already installed.${RC}"
    fi
}

setupWaydroid() {
    printf "%b\n" "${YELLOW}Setting up Waydroid...${RC}"
    elevated_execution systemctl enable --now waydroid-container
    elevated_execution waydroid init
    printf "%b\n" "${GREEN}Waydroid setup complete.${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
checkGpu
installWaydroid
setupWaydroid
