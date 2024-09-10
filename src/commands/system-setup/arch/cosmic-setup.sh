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
            ;;
        2)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs
            ;;
        3)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs power-profiles-daemon xorg-server xorg-xinit xorg-xrandr
            ;;
        4)
            $ESCALATION_TOOL pacman -S --needed --noconfirm cosmic linux-headers pacman-contrib xdg-user-dirs xorg-server xorg-xinit xorg-xrandr
            ;;
        *)
            echo "Invalid option. Please select 1 to 4."
            main_menu
            ;;
    esac

    $ESCALATION_TOOL systemctl enable cosmic-greeter.service
    xdg-user-dirs-update
}

# Check for NVIDIA GPU and run setup_nvidia if present
check_and_setup_nvidia() {
    if command -v lspci >/dev/null 2>&1 && lspci | grep -q "NVIDIA"; then
        setup_nvidia
    fi
}

# Main execution
checkEnv
checkEscalationTool
check_and_setup_nvidia
main_menu
