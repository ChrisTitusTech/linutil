#!/bin/sh -e

. ../../common-script.sh

checkGpu() {
    if ! command_exists lspci; then
        "$ESCALATION_TOOL" "$PACKAGER" install -y pciutils
    fi
    if ! lspci -nn | grep -qi "nvidia"; then
        printf "%b\n" "${RED}No NVIDIA GPU detected. Aborting.${RC}"
        exit 1
    fi
}

checkSecureBoot() {
    if command_exists mokutil && mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
        printf "%b\n" "${YELLOW}Secure Boot is enabled. The NVIDIA kernel module may need signing.${RC}"
        printf "%b\n" "${YELLOW}After installation, run: sudo mokutil --import /var/lib/dkms/mok.pub${RC}"
    fi
}

setupNvidiaRepo() {
    local distro
    case "$DTYPE" in
        debian) distro="debian" ;;
        ubuntu) distro="ubuntu" ;;
    esac

    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="sbsa" ;;
    esac

    if [ ! -f /usr/share/keyrings/cuda-archive-keyring.gpg ]; then
        printf "%b\n" "${CYAN}Setting up NVIDIA network repository...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" install -y wget
        wget "https://developer.download.nvidia.com/compute/cuda/repos/${distro}/${arch}/cuda-keyring_1.1-1_all.deb" -O /tmp/cuda-keyring.deb
        "$ESCALATION_TOOL" dpkg -i /tmp/cuda-keyring.deb
        rm -f /tmp/cuda-keyring.deb
        "$ESCALATION_TOOL" "$PACKAGER" update
    else
        printf "%b\n" "${CYAN}NVIDIA repository already configured.${RC}"
    fi
}

installDriver() {
    checkGpu
    checkSecureBoot

    "$ESCALATION_TOOL" "$PACKAGER" install -y linux-headers-"$(uname -r)"

    setupNvidiaRepo

    printf "%b\n" "${CYAN}Select driver type:${RC}"
    printf "%b\n" "1) Open Kernel Modules (recommended for Turing/Ada/Ampere GPUs)"
    printf "%b\n" "2) Proprietary Kernel Modules (for older GPUs)"
    printf "%b" "${YELLOW}Choice [1/2]: ${RC}"
    read -r driver_choice

    printf "%b\n" "${CYAN}Select installation type:${RC}"
    printf "%b\n" "1) Desktop + Compute (full driver stack with Xorg and CUDA)"
    printf "%b\n" "2) Desktop only (Xorg/Wayland, no CUDA)"
    printf "%b\n" "3) Compute only (headless, no display drivers)"
    printf "%b" "${YELLOW}Choice [1/2/3]: ${RC}"
    read -r install_type

    case "$DTYPE" in
        debian)
            "$ESCALATION_TOOL" apt-get install -y add-apt-repository
            "$ESCALATION_TOOL" add-apt-repository contrib -y
            case "$install_type" in
                2)
                    case "$driver_choice" in
                        1) "$ESCALATION_TOOL" apt-get -V install -y nvidia-driver nvidia-kernel-open-dkms ;;
                        *) "$ESCALATION_TOOL" apt-get -V install -y nvidia-driver nvidia-kernel-dkms ;;
                    esac
                    ;;
                3)
                    case "$driver_choice" in
                        1) "$ESCALATION_TOOL" apt-get -V install -y nvidia-driver-cuda nvidia-kernel-open-dkms ;;
                        *) "$ESCALATION_TOOL" apt-get -V install -y nvidia-driver-cuda nvidia-kernel-dkms ;;
                    esac
                    ;;
                *)
                    case "$driver_choice" in
                        1) "$ESCALATION_TOOL" apt-get -V install -y nvidia-open ;;
                        *) "$ESCALATION_TOOL" apt-get -V install -y cuda-drivers ;;
                    esac
                    ;;
            esac
            ;;
        ubuntu)
            case "$install_type" in
                2)
                    case "$driver_choice" in
                        1) "$ESCALATION_TOOL" apt-get -V install -y libnvidia-gl nvidia-dkms-open ;;
                        *) "$ESCALATION_TOOL" apt-get -V install -y libnvidia-gl nvidia-dkms ;;
                    esac
                    ;;
                3)
                    case "$driver_choice" in
                        1) "$ESCALATION_TOOL" apt-get -V install -y libnvidia-compute nvidia-dkms-open ;;
                        *) "$ESCALATION_TOOL" apt-get -V install -y libnvidia-compute nvidia-dkms ;;
                    esac
                    ;;
                *)
                    case "$driver_choice" in
                        1) "$ESCALATION_TOOL" apt-get install -y nvidia-open ;;
                        *) "$ESCALATION_TOOL" apt-get install -y cuda-drivers ;;
                    esac
                    ;;
            esac
            ;;
    esac

    printf "%b\n" "${GREEN}NVIDIA driver installation complete.${RC}"
}

setupNvidiaPersistenced() {
    if command_exists systemctl; then
        "$ESCALATION_TOOL" systemctl enable nvidia-persistenced 2>/dev/null || true
        "$ESCALATION_TOOL" systemctl restart nvidia-persistenced 2>/dev/null || true
        printf "%b\n" "${GREEN}nvidia-persistenced service restarted.${RC}"
    fi
}

verifyInstallation() {
    if [ -f /proc/driver/nvidia/version ]; then
        printf "%b\n" "${GREEN}Driver version:${RC}"
        cat /proc/driver/nvidia/version
    else
        printf "%b\n" "${YELLOW}Driver not yet loaded. Reboot required.${RC}"
    fi
}

printf "%b\n" "${YELLOW}NVIDIA Driver Installer for Debian/Ubuntu${RC}"
printf "%b\n" "${YELLOW}Follows NVIDIA official installation guide: https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/${RC}"

checkEnv
checkEscalationTool

case "$DTYPE" in
    debian|ubuntu) ;;
    *) printf "%b\n" "${RED}This script supports Debian and Ubuntu only.${RC}"; exit 1 ;;
esac

installDriver
setupNvidiaPersistenced
verifyInstallation

printf "%b" "${YELLOW}Reboot now? [y/N]: ${RC}"
read -r reboot_choice
case "$reboot_choice" in
    y|Y) "$ESCALATION_TOOL" reboot ;;
    *) printf "%b\n" "${YELLOW}Reboot later to load the NVIDIA driver.${RC}" ;;
esac
