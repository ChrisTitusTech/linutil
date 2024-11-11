#!/bin/sh -e

. ../common-script.sh

checkGpu() {
    if lspci | grep -i nvidia >/dev/null; then
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

                if ! command_exists dkms; then
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm dkms
                fi

                installed_kernels=$("$PACKAGER" -Q | grep -E '^linux(| |-rt|-rt-lts|-hardened|-zen|-lts)[^-headers]' | cut -d ' ' -f 1)
                for kernel in $installed_kernels; do
                    header="${kernel}-headers"
                    printf "%b\n" "${CYAN}Installing headers for $kernel...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$header"
                done

                "$AUR_HELPER" -S --needed --noconfirm binder_linux-dkms
                "$ESCALATION_TOOL" modprobe binder-linux device=binder,hwbinder,vndbinder
                ;;
            apt-get | nala)
                curl https://repo.waydro.id | "$ESCALATION_TOOL" sh
                "$ESCALATION_TOOL" "$PACKAGER" install -y waydroid
                if command_exists dkms; then
                    "$ESCALATION_TOOL" "$PACKAGER" install -y git
                    mkdir -p "$HOME/.local/share/"
                    git clone https://github.com/choff/anbox-modules.git "$HOME/.local/share/anbox-modules"
                    cd "$HOME/.local/share/anbox-modules"
                    "$ESCALATION_TOOL" cp anbox.conf /etc/modules-load.d/
                    "$ESCALATION_TOOL" cp 99-anbox.rules /lib/udev/rules.d/
                    "$ESCALATION_TOOL" cp -rT ashmem /usr/src/anbox-ashmem-1
                    "$ESCALATION_TOOL" cp -rT binder /usr/src/anbox-binder-1
                    "$ESCALATION_TOOL" dkms install anbox-ashmem/1
                    "$ESCALATION_TOOL" dkms install anbox-binder/1
                fi
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y waydroid
                if command_exists dkms; then
                    "$ESCALATION_TOOL" "$PACKAGER" install -y git
                    mkdir -p "$HOME/.local/share/"
                    git clone https://github.com/choff/anbox-modules.git "$HOME/.local/share/anbox-modules"
                    cd "$HOME/.local/share/anbox-modules"
                    "$ESCALATION_TOOL" cp anbox.conf /etc/modules-load.d/
                    "$ESCALATION_TOOL" cp 99-anbox.rules /lib/udev/rules.d/
                    "$ESCALATION_TOOL" cp -rT ashmem /usr/src/anbox-ashmem-1
                    "$ESCALATION_TOOL" cp -rT binder /usr/src/anbox-binder-1
                    "$ESCALATION_TOOL" dkms install anbox-ashmem/1
                    "$ESCALATION_TOOL" dkms install anbox-binder/1
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
    "$ESCALATION_TOOL" systemctl enable --now waydroid-container
    "$ESCALATION_TOOL" waydroid init
    printf "%b\n" "${GREEN}Waydroid setup complete.${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
checkGpu
installWaydroid
setupWaydroid
