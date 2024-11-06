#!/bin/sh -e

. ../../common-script.sh

LIBVA_DIR="$HOME/.local/share/linutil/libva"
MPV_CONF="$HOME/.config/mpv/mpv.conf"

installDeps() {
    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel dkms ninja meson git

    installed_kernels=$("$PACKAGER" -Q | grep -E '^linux(| |-rt|-rt-lts|-hardened|-zen|-lts)[^-headers]' | cut -d ' ' -f 1)

    for kernel in $installed_kernels; do
        header="${kernel}-headers"
        printf "%b\n" "${CYAN}Installing headers for $kernel...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$header"
    done
}

checkNvidiaHardware() {
    # Refer https://nouveau.freedesktop.org/CodeNames.html for model code names
    model=$(lspci -k | grep -A 2 -E "(VGA|3D)" | grep NVIDIA | sed 's/.*Corporation //;s/ .*//' | cut -c 1-2)
    case "$model" in
        GM | GP | GV) return 1 ;;
        TU | GA | AD) return 0 ;;
        *) printf "%b\n" "${RED}Unsupported hardware." && exit 1 ;;
    esac
}

checkIntelHardware() {
    model=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | cut -c 2-3)
    [ "$model" -ge 11 ]
}

promptUser() {
    printf "%b" "Do you want to $1 ? [y/N]:"
    read -r confirm
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]
}

setKernelParam() {
    PARAMETER="$1"

    if grep -q "$PARAMETER" /etc/default/grub; then
        printf "%b\n" "${YELLOW}NVIDIA modesetting is already enabled in GRUB.${RC}"
    else
        "$ESCALATION_TOOL" sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ $PARAMETER\"/" /etc/default/grub
        printf "%b\n" "${CYAN}Added $PARAMETER to /etc/default/grub.${RC}"
        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

setupHardwareAcceleration() {
    if ! command_exists grub-mkconfig; then
        printf "%b\n" "${RED}Currently hardware acceleration is only available with GRUB.${RC}"
        return
    fi

    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm libva-nvidia-driver

    mkdir -p "$HOME/.local/share/linutil"
    if [ -d "$LIBVA_DIR" ]; then
        rm -rf "$LIBVA_DIR"
    fi

    printf "%b\n" "${YELLOW}Cloning libva from https://github.com/intel/libva in ${LIBVA_DIR}${RC}"
    git clone --branch=v2.22-branch --depth=1 https://github.com/intel/libva "$LIBVA_DIR"

    mkdir -p "$LIBVA_DIR/build"
    cd "$LIBVA_DIR/build" && arch-meson .. -Dwith_legacy=nvctrl && ninja
    "$ESCALATION_TOOL" ninja install

    "$ESCALATION_TOOL" sed -i '/^MOZ_DISABLE_RDD_SANDBOX/d' "/etc/environment"
    "$ESCALATION_TOOL" sed -i '/^LIBVA_DRIVER_NAME/d' "/etc/environment"

    printf "LIBVA_DRIVER_NAME=nvidia\nMOZ_DISABLE_RDD_SANDBOX=1" | "$ESCALATION_TOOL" tee -a /etc/environment >/dev/null

    printf "%b\n" "${GREEN}Hardware Acceleration setup completed successfully.${RC}"

    if promptUser "enable Hardware Acceleration in MPV player"; then
        mkdir -p "$HOME/.config/mpv"
        if [ -f "$MPV_CONF" ]; then
            sed -i '/^hwdec/d' "$MPV_CONF"
        fi
        printf "hwdec=auto" | tee -a "$MPV_CONF" >/dev/null
        printf "%b\n" "${GREEN}MPV Hardware Acceleration enabled successfully.${RC}"
    fi
}

installDriver() {
    # Refer https://wiki.archlinux.org/title/NVIDIA for open-dkms or dkms driver selection
    if checkNvidiaHardware && promptUser "install nvidia's open source drivers"; then
        printf "%b\n" "${YELLOW}Installing nvidia open source driver...${RC}"
        installDeps
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm nvidia-open-dkms nvidia-utils
    else
        printf "%b\n" "${YELLOW}Installing nvidia proprietary driver...${RC}"
        installDeps
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm nvidia-dkms nvidia-utils
    fi

    if checkIntelHardware; then
        setKernelParam "ibt=off"
    fi

    # Refer https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Preserve_video_memory_after_suspend
    setKernelParam "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "$ESCALATION_TOOL" systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

    printf "%b\n" "${GREEN}Driver installed successfully.${RC}"
    if promptUser "setup Hardware Acceleration"; then
        setupHardwareAcceleration
    fi

    printf "%b\n" "${GREEN}Please reboot your system for the changes to take effect.${RC}"
}

checkEnv
checkEscalationTool
installDriver
