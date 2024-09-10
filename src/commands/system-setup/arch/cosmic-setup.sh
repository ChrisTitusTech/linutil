#!/bin/sh -e

# Source the common script
. ../../common-script.sh

# Function to handle NVIDIA package setup
setup_nvidia() {
    if pacman -Qi nvidia >/dev/null 2>&1; then
        echo "Removing 'nvidia' package..."
        $ESCALATION_TOOL pacman -Rns --noconfirm nvidia
    fi

    echo "Installing NVIDIA packages..."
    $ESCALATION_TOOL pacman -S --needed --noconfirm nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings

    echo "Configuring /etc/mkinitcpio.conf for NVIDIA modules..."
    if $ESCALATION_TOOL grep -Eq '^MODULES=.*\bnvidia\b.*\bnvidia_modeset\b.*\bnvidia_uvm\b.*\bnvidia_drm\b' /etc/mkinitcpio.conf; then
        echo "NVIDIA modules already present in /etc/mkinitcpio.conf."
    else
        $ESCALATION_TOOL sed -i '/^MODULES=/ s/()/nvidia nvidia_modeset nvidia_uvm nvidia_drm/' /etc/mkinitcpio.conf
        echo "NVIDIA modules added to /etc/mkinitcpio.conf."
    fi

    echo "Checking bootloader entries for NVIDIA DRM modeset..."
    for entry in /boot/loader/entries/*.conf; do
        if $ESCALATION_TOOL grep -q '^options' "$entry"; then
            if ! $ESCALATION_TOOL grep -q 'nvidia-drm.modeset=1' "$entry"; then
                $ESCALATION_TOOL sed -i 's/^options.*/& nvidia-drm.modeset=1/' "$entry"
                echo "nvidia-drm.modeset=1 added to $entry."
            else
                echo "nvidia-drm.modeset=1 already present in $entry."
            fi
        fi
    done

    echo "Creating NVIDIA hook..."
    if [ ! -d /etc/pacman.d/hooks ]; then
        $ESCALATION_TOOL mkdir -p /etc/pacman.d/hooks
    fi

    $ESCALATION_TOOL tee /etc/pacman.d/hooks/nvidia.hook > /dev/null <<EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia

[Action]
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF

    echo "NVIDIA hook created at /etc/pacman.d/hooks/nvidia.hook."
}

# Main menu for Cosmic Installation without dialog
main_menu() {
    echo ">> Cosmic Alpha 1 Install <<"
    echo "1) Complete: Full Cosmic Install (Wayland)"
    echo "2) Selective: Partial Installation (Wayland)"
    echo "3) Complete: Full Cosmic Install (X11)"
    echo "4) Selective: Partial Installation (X11)"
    echo "Please choose an option (1-4):"
    read -r CHOICE

    case "$CHOICE" in
        1)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs power-profiles-daemon wayland-protocols wayland-utils
            setup_nvidia
            ;;
        2)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs
            setup_nvidia
            ;;
        3)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs power-profiles-daemon xorg-server xorg-xinit xorg-xrandr
            setup_nvidia
            ;;
        4)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs xorg-server xorg-xinit xorg-xrandr
            setup_nvidia
            ;;
        *)
            echo "Invalid option. Please select 1 to 4."
            main_menu
            ;;
    esac

    $ESCALATION_TOOL systemctl enable cosmic-greeter.service
    xdg-user-dirs-update
}

# Check GPU compatibility for Wayland and X11
check_gpu_cosmic_compatibility() {
    if command -v lspci >/dev/null 2>&1; then
        GPU_INFO=$(lspci | grep -E "VGA|3D")

        case "$GPU_INFO" in
            *NVIDIA*)
                if echo "$GPU_INFO" | grep -Eq "GTX (9[0-9]{2}|[1-9][0-9]{3})|RTX|Titan|A[0-9]{2,3}"; then
                    echo "Your NVIDIA GPU should support both Wayland and X11."
                else
                    echo "Older NVIDIA GPU detected. Only 900 series and newer support Cosmic Desktop on both Wayland and X11."
                fi
                ;;
            *Intel*)
                if echo "$GPU_INFO" | grep -Eq "HD Graphics ([4-9][0-9]{2}|[1-9][0-9]{3,})|Iris|Xe"; then
                    echo "Your Intel GPU should support both Wayland and X11."
                else
                    echo "Older Intel GPU detected. Only HD Graphics 4000 and newer support Cosmic Desktop on both Wayland and X11."
                fi
                ;;
            *AMD*)
                if echo "$GPU_INFO" | grep -Eq "RX (4[8-9][0-9]|[5-9][0-9]{2,})|VEGA|RDNA|RADEON PRO"; then
                    echo "Your AMD GPU should support both Wayland and X11."
                else
                    echo "Older AMD GPU detected. Only RX 480 and newer support Cosmic Desktop on both Wayland and X11."
                fi
                ;;
            *)
                echo "Unknown or unsupported GPU detected. Compatibility uncertain."
                ;;
        esac
    fi
}

# Main execution
checkEnv
checkEscalationTool
check_gpu_cosmic_compatibility
main_menu
