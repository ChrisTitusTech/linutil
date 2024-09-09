#!/bin/sh -e

# Source the common script
. "../../common-script.sh"

# Main menu for Cosmic Installation
main_menu() {
    CHOICE=$(dialog --stdout --title ">> Cosmic Alpha 1 Install <<" --menu "\nChoose how to install Cosmic Alpha 1" 15 60 4 \
        1 "Complete: Full Cosmic Install" \
        2 "Selective: Partial Installation")

    case "$CHOICE" in
        1)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs power-profiles-daemon wayland-protocols wayland-utils
            ;;
        2)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs
            $ESCALATION_TOOL systemctl enable power-profiles-daemon
            ;;
        *)
            if [ -z "$CHOICE" ]; then
                exit 0
            else
                dialog --msgbox "Invalid option. Select 1 or 2." 10 40
                main_menu
            fi
            ;;
    esac

    $ESCALATION_TOOL systemctl enable cosmic-greeter.service
    xdg-user-dirs-update
    $ESCALATION_TOOL systemctl enable power-profiles-daemon.service
}

# Check GPU compatibility for Wayland
check_gpu_cosmic_compatibility() {
    if command -v lspci >/dev/null 2>&1; then
        GPU_INFO=$(lspci | grep -E "VGA|3D")

        case "$GPU_INFO" in
            *NVIDIA*)
                if echo "$GPU_INFO" | grep -Eq "GTX (9[0-9]{2}|[1-9][0-9]{3})|RTX|Titan|A[0-9]{2,3}"; then
                    echo "Your NVIDIA GPU should support Cosmic Desktop."
                else
                    echo "Older NVIDIA GPU detected. Only 900 series and newer support Cosmic Desktop."
                fi
                ;;
            *Intel*)
                if echo "$GPU_INFO" | grep -Eq "HD Graphics ([4-9][0-9]{2}|[1-9][0-9]{3,})|Iris|Xe"; then
                    echo "Your Intel GPU should support Cosmic Desktop."
                else
                    echo "Older Intel GPU detected. Only HD Graphics 4000 and newer support Cosmic Desktop."
                fi
                ;;
            *AMD*)
                if echo "$GPU_INFO" | grep -Eq "RX (4[8-9][0-9]|[5-9][0-9]{2,})|VEGA|RDNA|RADEON PRO"; then
                    echo "Your AMD GPU should support Cosmic Desktop."
                else
                    echo "Older AMD GPU detected. Only RX 480 and newer support Cosmic Desktop."
                fi
                ;;
            *)
                echo "Unknown or unsupported GPU detected. Compatibility uncertain."
                ;;
        esac
    else
        echo "Cannot detect GPU. 'lspci' command not found."
    fi
}

# Toolkit integration
install_aur_helper() {
    . "./paru-setup.sh" || . "./yay-setup.sh"
}

# Main execution
checkEnv
checkEscalationTool
check_gpu_cosmic_compatibility
install_aur_helper

echo "Proceeding with the installation..."
main_menu

echo "Installing PipeWire packages..."
$ESCALATION_TOOL pacman -S --needed --noconfirm gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-good gst-plugins-ugly libdvdcss alsa-utils alsa-firmware pavucontrol lib32-pipewire-jack libpipewire pipewire-v4l2 pipewire-x11-bell pipewire-zeroconf realtime-privileges sof-firmware ffmpeg ffmpegthumbs ffnvcodec-headers

echo "Installing Bluetooth packages..."
$ESCALATION_TOOL pacman -S --needed --noconfirm bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools
$ESCALATION_TOOL systemctl enable bluetooth.service

# Check if GRUB is installed and add OS-Prober support
if command -v grub-mkconfig >/dev/null 2>&1; then
    echo "GRUB is installed. Adding support for OS-Prober."
    $ESCALATION_TOOL pacman -S --needed --noconfirm os-prober
    $ESCALATION_TOOL sed -i 's/#[[:space:]]*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    $ESCALATION_TOOL os-prober
    $ESCALATION_TOOL grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "GRUB not found. Skipping OS-Prober."
fi

# VM detection and relevant package installation
VM_TYPE=$(systemd-detect-virt)
case "$VM_TYPE" in
    oracle)
        $ESCALATION_TOOL pacman -S --needed --noconfirm virtualbox-guest-utils
        ;;
    kvm)
        $ESCALATION_TOOL pacman -S --needed --noconfirm qemu-guest-agent spice-vdagent
        ;;
    vmware)
        $ESCALATION_TOOL pacman -S --needed --noconfirm xf86-video-vmware open-vm-tools xf86-input-vmmouse
        $ESCALATION_TOOL systemctl enable vmtoolsd.service
        ;;
    *)
        echo "Not running in a VM."
        ;;
esac
