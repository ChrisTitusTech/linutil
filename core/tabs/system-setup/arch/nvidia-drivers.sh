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
        
        if ! "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$header" ; then
            printf "%b\n" "${RED}Failed to install headers.${RC}"
            printf "%b" "${YELLOW}Do you want to continue anyway? [y/N]: ${RC}"
            read -r continue_anyway
            if ! [ "$continue_anyway" = "y" ] && ! [ "$continue_anyway" = "Y" ]; then
                printf "%b\n" "${RED}Aborting installation.${RC}"
                exit 1
            fi
            printf "%b\n" "${YELLOW}Continuing...${RC}"
        fi    
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

checkIbtSupport() {
    grep -qw "ibt" /proc/cpuinfo
}

promptUser() {
    printf "%b" "Do you want to $1 ? [y/N]:"
    read -r confirm
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]
}

backupConfig() {
    if [ -f "$1" ] && [ ! -f "$1.linutil.bak" ]; then
        "$ESCALATION_TOOL" cp "$1" "$1.linutil.bak"
    fi
}

updateGrubKernelParam() {
    parameter="$1"
    grub_config="/etc/default/grub"

    [ -f "$grub_config" ] || return 1

    if grep -Fq -- "$parameter" "$grub_config"; then
        printf "%b\n" "${YELLOW}${parameter} is already set in GRUB.${RC}"
    else
        backupConfig "$grub_config"
        if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" "$grub_config"; then
            "$ESCALATION_TOOL" sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ $parameter\"/" "$grub_config"
        else
            printf "GRUB_CMDLINE_LINUX_DEFAULT=\"%s\"\n" "$parameter" | "$ESCALATION_TOOL" tee -a "$grub_config" >/dev/null
        fi
        printf "%b\n" "${CYAN}Added ${parameter} to ${grub_config}.${RC}"
    fi

    if command_exists grub-mkconfig && [ -d /boot/grub ]; then
        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "${YELLOW}GRUB config updated. Run grub-mkconfig manually if your distro requires it.${RC}"
    fi

    return 0
}

updateSystemdBootKernelParam() {
    parameter="$1"
    found_entry=false
    updated_entry=false

    for entry in /boot/loader/entries/*.conf /efi/loader/entries/*.conf; do
        [ -f "$entry" ] || continue
        found_entry=true

        if grep -Fq -- "$parameter" "$entry"; then
            printf "%b\n" "${YELLOW}${parameter} is already set in ${entry}.${RC}"
            updated_entry=true
            continue
        fi

        if grep -q "^options " "$entry"; then
            backupConfig "$entry"
            "$ESCALATION_TOOL" sed -i "/^options / s/$/ $parameter/" "$entry"
            printf "%b\n" "${CYAN}Added ${parameter} to ${entry}.${RC}"
            updated_entry=true
        else
            printf "%b\n" "${YELLOW}Skipped ${entry}: no options line found.${RC}"
        fi
    done

    [ "$found_entry" = true ] && [ "$updated_entry" = true ]
}

updateKernelInstallCmdline() {
    parameter="$1"
    cmdline="/etc/kernel/cmdline"

    [ -f "$cmdline" ] || return 1

    if grep -Fq -- "$parameter" "$cmdline"; then
        printf "%b\n" "${YELLOW}${parameter} is already set in ${cmdline}.${RC}"
    else
        backupConfig "$cmdline"
        "$ESCALATION_TOOL" sed -i "1 s/$/ $parameter/" "$cmdline"
        printf "%b\n" "${CYAN}Added ${parameter} to ${cmdline}.${RC}"
        printf "%b\n" "${YELLOW}Regenerate your kernel-install entries or UKIs if your setup requires it.${RC}"
    fi

    return 0
}

updateLimineKernelParam() {
    parameter="$1"

    for limine_config in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf /boot/efi/EFI/limine/limine.conf /efi/EFI/limine/limine.conf /etc/limine.conf; do
        [ -f "$limine_config" ] || continue

        if grep -Fq -- "$parameter" "$limine_config"; then
            printf "%b\n" "${YELLOW}${parameter} is already set in ${limine_config}.${RC}"
        elif grep -q "^[[:space:]]*CMDLINE=" "$limine_config"; then
            backupConfig "$limine_config"
            "$ESCALATION_TOOL" sed -i "/^[[:space:]]*CMDLINE=/ s/$/ $parameter/" "$limine_config"
            printf "%b\n" "${CYAN}Added ${parameter} to ${limine_config}.${RC}"
        else
            printf "%b\n" "${YELLOW}Skipped ${limine_config}: no CMDLINE entry found.${RC}"
            return 1
        fi
        return 0
    done

    return 1
}

updateRefindKernelParam() {
    parameter="$1"

    for refind_config in /boot/refind_linux.conf /boot/efi/EFI/refind/refind_linux.conf /efi/EFI/refind/refind_linux.conf; do
        [ -f "$refind_config" ] || continue

        if grep -Fq -- "$parameter" "$refind_config"; then
            printf "%b\n" "${YELLOW}${parameter} is already set in ${refind_config}.${RC}"
        else
            backupConfig "$refind_config"
            "$ESCALATION_TOOL" sed -i "/^[[:space:]]*#/! s/\"$/ $parameter\"/" "$refind_config"
            printf "%b\n" "${CYAN}Added ${parameter} to ${refind_config}.${RC}"
        fi

        return 0
    done

    return 1
}

setKernelParam() {
    parameter="$1"

    if updateGrubKernelParam "$parameter" ||
        updateSystemdBootKernelParam "$parameter" ||
        updateKernelInstallCmdline "$parameter" ||
        updateLimineKernelParam "$parameter" ||
        updateRefindKernelParam "$parameter"; then
        return 0
    fi

    printf "%b\n" "${YELLOW}Could not find a supported bootloader config to add ${parameter}.${RC}"
    printf "%b\n" "${YELLOW}Add it manually to your kernel command line if your setup requires it.${RC}"
}

setupHardwareAcceleration() {
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

    if checkIbtSupport; then
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
