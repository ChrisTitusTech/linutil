#!/bin/sh -e
# shellcheck disable=SC2086

. ../common-script.sh

gpu_lines=""
gpu_vendor=""

prompt_yes_no() {
    question=$1
    printf "%b" "${YELLOW}${question} [y/N]: ${RC}"
    read -r response
    [ "$response" = "y" ] || [ "$response" = "Y" ]
}

detect_gpus() {
    if ! command_exists lspci; then
        printf "%b\n" "${YELLOW}pciutils is required for GPU detection. Installing...${RC}"
        case "$PACKAGER" in
            pacman) "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm pciutils ;;
            apt-get | nala)
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y pciutils
                ;;
            dnf) "$ESCALATION_TOOL" "$PACKAGER" install -y pciutils ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install pciutils
                ;;
            apk) "$ESCALATION_TOOL" "$PACKAGER" add pciutils ;;
            xbps-install) "$ESCALATION_TOOL" "$PACKAGER" -Sy pciutils ;;
            eopkg) "$ESCALATION_TOOL" "$PACKAGER" install -y pciutils ;;
        esac
    fi

    gpu_lines=$(lspci -nn | grep -Ei 'VGA|3D|Display' || true)
    if [ -z "$gpu_lines" ]; then
        printf "%b\n" "${RED}No GPU detected through lspci. Aborting.${RC}"
        exit 1
    fi

    if printf "%s\n" "$gpu_lines" | grep -qi "nvidia"; then
        gpu_vendor="nvidia"
    elif printf "%s\n" "$gpu_lines" | grep -Eqi "amd|advanced micro devices|ati"; then
        gpu_vendor="amd"
    elif printf "%s\n" "$gpu_lines" | grep -qi "intel"; then
        gpu_vendor="intel"
    else
        printf "%b\n" "${RED}Detected GPU is currently unsupported by this script.${RC}"
        exit 1
    fi
}

install_nvidia() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings
            ;;
        apt-get | nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            if command_exists ubuntu-drivers; then
                "$ESCALATION_TOOL" ubuntu-drivers autoinstall
            else
                "$ESCALATION_TOOL" "$PACKAGER" install -y nvidia-driver
            fi
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
            ;;
        zypper)
            printf "%b\n" "${YELLOW}Automatic NVIDIA install on zypper depends on your enabled repos.${RC}"
            printf "%b\n" "${YELLOW}Install manually with: sudo zypper install nvidia-video-G06${RC}"
            return 1
            ;;
        apk)
            printf "%b\n" "${YELLOW}NVIDIA proprietary drivers are not provided by default on Alpine.${RC}"
            return 1
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy nvidia-dkms nvidia
            ;;
        eopkg)
            printf "%b\n" "${YELLOW}Solus NVIDIA support is hardware-generation specific. Install from Driver Management.${RC}"
            return 1
            ;;
    esac
}

install_amd() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver
            ;;
        apt-get | nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y mesa-vulkan-drivers mesa-va-drivers firmware-amd-graphics
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y mesa-vulkan-drivers mesa-va-drivers
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install Mesa-vulkan-drivers Mesa-libva
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add mesa-va-gallium mesa-vulkan-radeon
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy mesa-dri mesa-vulkan-radeon mesa-vaapi
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y mesa-dri-drivers
            ;;
    esac
}

install_intel() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm mesa vulkan-intel intel-media-driver
            ;;
        apt-get | nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y mesa-vulkan-drivers intel-media-va-driver i965-va-driver
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y mesa-vulkan-drivers intel-media-driver libva-intel-driver
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install Mesa-vulkan-drivers intel-media-driver libva-intel-driver
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add mesa-va-gallium mesa-vulkan-intel
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy mesa-dri mesa-vulkan-intel intel-video-accel
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y mesa-dri-drivers
            ;;
    esac
}

handle_nixos() {
    detect_gpus
    printf "%b\n" "${CYAN}Detected GPU:${RC}"
    printf "%s\n" "$gpu_lines"
    printf "%b\n" "${YELLOW}NixOS GPU drivers are declarative.${RC}"
    printf "%b\n" "${YELLOW}Add this to /etc/nixos/configuration.nix and run: sudo nixos-rebuild switch${RC}"

    case "$gpu_vendor" in
        nvidia)
            cat <<'EOF'
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  open = true;
  nvidiaSettings = true;
};
EOF
            ;;
        amd)
            cat <<'EOF'
services.xserver.videoDrivers = [ "amdgpu" ];
hardware.graphics.enable = true;
EOF
            ;;
        intel)
            cat <<'EOF'
services.xserver.videoDrivers = [ "modesetting" ];
hardware.graphics.enable = true;
EOF
            ;;
    esac

    exit 0
}

install_driver() {
    case "$gpu_vendor" in
        nvidia) install_nvidia ;;
        amd) install_amd ;;
        intel) install_intel ;;
    esac
}

main() {
    checkArch
    checkEscalationTool
    checkDistro

    if [ "$DTYPE" = "nixos" ]; then
        handle_nixos
    fi

    checkCommandRequirements "curl groups $ESCALATION_TOOL"
    checkPackageManager 'nala apt-get dnf pacman zypper apk xbps-install eopkg'
    checkCurrentDirectoryWritable
    checkSuperUser
    checkAURHelper

    detect_gpus
    printf "%b\n" "${CYAN}Detected GPU:${RC}"
    printf "%s\n" "$gpu_lines"

    if ! prompt_yes_no "Install recommended ${gpu_vendor} driver stack now?"; then
        printf "%b\n" "${YELLOW}Aborted by user.${RC}"
        exit 0
    fi

    if install_driver; then
        printf "%b\n" "${GREEN}Driver installation finished.${RC}"
        printf "%b\n" "${GREEN}Reboot is recommended for the changes to fully apply.${RC}"
    else
        printf "%b\n" "${YELLOW}No changes were applied automatically for this distro/GPU combination.${RC}"
        exit 1
    fi
}

main
