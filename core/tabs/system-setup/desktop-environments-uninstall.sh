#!/bin/sh -e

. ../common-script.sh

# Check if WM/DE is installed
is_installed() {
    pkg_manager=$1
    check_type=$2
    value=$3
    case $check_type in
        bin)
            command -v "$value" >/dev/null 2>&1 && return 0 || return 1
            ;;
        pkg)
            case $pkg_manager in
                apt-get|nala)
                    dpkg -l | grep -qw "$value" && return 0 || return 1
                    ;;
                pacman)
                    pacman -Qs "$value" >/dev/null 2>&1 && return 0 || return 1
                    ;;
                dnf)
                    rpm -q "$value" >/dev/null 2>&1 && return 0 || return 1
                    ;;
                zypper)
                    rpm -q "$value" >/dev/null 2>&1 && return 0 || return 1
                    ;;
            esac
            ;;
    esac
    return 1
}

# Uninstal packages
uninstall_packages() {
    pkg_manager=$1
    shift
    # shellcheck disable=SC2086
    case $pkg_manager in
        pacman)
            $ESCALATION_TOOL $AUR_HELPER -Rns "$@" --noconfirm || true
            ;;
        apt-get|nala)
            $ESCALATION_TOOL $pkg_manager remove --purge "$@" -y || true
            $ESCALATION_TOOL $pkg_manager autoremove -y || true
            ;;
        dnf)
            $ESCALATION_TOOL $pkg_manager remove "$@" -y || true
            ;;
        zypper)
            $ESCALATION_TOOL $pkg_manager remove "$@" -y || true
            ;;
    esac
}

# Uninstall DEs
uninstall_desktop() {
    pkg_manager=$1
    desktop=$2
    packages=()
    config_dirs=()

    case $desktop in
        "GNOME")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "ubuntu-gnome-desktop"
                        "gnome-shell"
                        "gnome-session"
                        "gnome-control-center"
                        "gnome-tweaks"
                        "gnome-software"
                        "nautilus"
                    )
                    ;;
                "pacman")
                    packages=(
                        "gnome"
                        "gnome-extra"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@gnome-desktop"
                        "gnome-shell"
                        "gnome-session"
                        "gnome-control-center"
                        "gnome-tweaks"
                        "gnome-software"
                        "nautilus"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-gnome-gnome"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/gnome-shell"
                "$HOME/.local/share/gnome-shell"
                "$HOME/.local/share/gnome-settings-daemon"
                "$HOME/.local/share/gnome-shell"
                "$HOME/.config/dconf"
            )
            ;;
        "KDE")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "kubuntu-desktop"
                        "plasma-desktop"
                        "kde-standard"
                    )
                    ;;
                "pacman")
                    packages=(
                        "plasma"
                        "kde-applications"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@kde-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-kde-kde_plasma"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
                "$HOME/.config/plasmarc"
                "$HOME/.config/plasma-workspace"
                "$HOME/.kde"
                "$HOME/.local/share/kwin"
            )
            ;;
        "XFCE")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "xfce4"
                        "xfce4-goodies"
                    )
                    ;;
                "pacman")
                    packages=(
                        "xfce4"
                        "xfce4-goodies"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@xfce-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-xfce-xfce"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/xfce4"
                "$HOME/.local/share/xfce4"
                "$HOME/.cache/xfce4"
            )
            ;;
        "Cinnamon")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "cinnamon-desktop-environment"
                    )
                    ;;
                "pacman")
                    packages=(
                        "cinnamon"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@cinnamon-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-cinnamon-cinnamon"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.cinnamon"
                "$HOME/.local/share/cinnamon"
                "$HOME/.config/cinnamon"
            )
            ;;
        "MATE")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "ubuntu-mate-desktop"
                    )
                    ;;
                "pacman")
                    packages=(
                        "mate"
                        "mate-extra"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@mate-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-mate-mate"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/mate"
                "$HOME/.local/share/mate"
            )
            ;;
        "Budgie")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "ubuntu-budgie-desktop"
                    )
                    ;;
                "pacman")
                    packages=(
                        "budgie-desktop"
                    )
                    ;;
                "dnf")
                    packages=(
                        "budgie-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "budgie-desktop"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/budgie-desktop"
                "$HOME/.local/share/budgie-desktop"
            )
            ;;
        "LXQt")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "lxqt"
                    )
                    ;;
                "pacman")
                    packages=(
                        "lxqt"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@lxqt-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-lxqt-lxqt"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/lxqt"
                "$HOME/.local/share/lxqt"
            )
            ;;
        "LXDE")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "lxde"
                    )
                    ;;
                "pacman")
                    packages=(
                        "lxde"
                    )
                    ;;
                "dnf")
                    packages=(
                        "@lxde-desktop"
                    )
                    ;;
                "zypper")
                    packages=(
                        "patterns-lxde-lxde"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/lxde"
                "$HOME/.local/share/lxde"
            )
            ;;
        "i3")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "i3"
                        "i3-wm"
                        "i3lock"
                        "i3status"
                    )
                    ;;
                "pacman")
                    packages=(
                        "i3-wm"
                        "i3lock"
                        "i3status"
                    )
                    ;;
                "dnf")
                    packages=(
                        "i3"
                        "i3lock"
                        "i3status"
                    )
                    ;;
                "zypper")
                    packages=(
                        "i3"
                        "i3lock"
                        "i3status"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/i3"
                "$HOME/.i3"
            )
            ;;
        "Sway")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "sway"
                        "swaylock"
                        "swayidle"
                    )
                    ;;
                "pacman")
                    packages=(
                        "sway"
                        "swaylock"
                        "swayidle"
                    )
                    ;;
                "dnf")
                    packages=(
                        "sway"
                        "swaylock"
                        "swayidle"
                    )
                    ;;
                "zypper")
                    packages=(
                        "sway"
                        "swaylock"
                        "swayidle"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/sway"
            )
            ;;
        "DWM")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "dwm"
                    )
                    ;;
                "pacman")
                    packages=(
                        "dwm"
                    )
                    ;;
                "dnf")
                    packages=(
                        "dwm"
                    )
                    ;;
                "zypper")
                    packages=(
                        "dwm"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.dwm"
            )
            ;;
        "Awesome")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "awesome"
                    )
                    ;;
                "pacman")
                    packages=(
                        "awesome"
                    )
                    ;;
                "dnf")
                    packages=(
                        "awesome"
                    )
                    ;;
                "zypper")
                    packages=(
                        "awesome"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/awesome"
            )
            ;;
        "BSPWM")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "bspwm"
                        "sxhkd"
                    )
                    ;;
                "pacman")
                    packages=(
                        "bspwm"
                        "sxhkd"
                    )
                    ;;
                "dnf")
                    packages=(
                        "bspwm"
                        "sxhkd"
                    )
                    ;;
                "zypper")
                    packages=(
                        "bspwm"
                        "sxhkd"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/bspwm"
                "$HOME/.config/sxhkd"
            )
            ;;
        "Openbox")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "openbox"
                    )
                    ;;
                "pacman")
                    packages=(
                        "openbox"
                    )
                    ;;
                "dnf")
                    packages=(
                        "openbox"
                    )
                    ;;
                "zypper")
                    packages=(
                        "openbox"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.config/openbox"
            )
            ;;
        "Fluxbox")
            case $pkg_manager in
                "apt-get"|"nala")
                    packages=(
                        "fluxbox"
                    )
                    ;;
                "pacman")
                    packages=(
                        "fluxbox"
                    )
                    ;;
                "dnf")
                    packages=(
                        "fluxbox"
                    )
                    ;;
                "zypper")
                    packages=(
                        "fluxbox"
                    )
                    ;;
            esac
            config_dirs=(
                "$HOME/.fluxbox"
            )
            ;;
        *)
            echo "Unsupported desktop environment: $desktop"
            return 1
            ;;
    esac

    echo "Uninstalling $desktop..."
    
    # Remove packages
    echo "Removing packages..."
    uninstall_packages "$pkg_manager" "${packages[@]}"
    
    # Clean up configuration files
    echo "Cleaning up configuration files..."
    for dir in "${config_dirs[@]}"; do
        if [ -e "$dir" ]; then
            echo "Removing $dir"
            rm -rf "$dir"
        fi
    done

    # Additional cleanup for specific package managers
    case $pkg_manager in
        "apt-get"|"nala")
            sudo apt-get autoremove -y || true
            sudo apt-get clean || true
            ;;
        "pacman")
            sudo pacman -Scc --noconfirm || true
            ;;
        "dnf")
            sudo dnf autoremove -y || true
            sudo dnf clean all || true
            ;;
        "zypper")
            sudo zypper clean || true
            ;;
    esac

    echo "Uninstallation of $desktop completed."
}



# Main script

main() {
    echo "Desktop Environment Uninstaller"
    echo "=============================="

    # List of DEs/WMs and their detection methods
    # Format: NAME|TYPE|VALUE
    DE_LIST=(
        "GNOME|bin|gnome-shell"
        "KDE|bin|startplasma-x11"
        "XFCE|bin|xfce4-session"
        "Cinnamon|bin|cinnamon-session"
        "MATE|bin|mate-session"
        "Budgie|bin|budgie-desktop"
        "LXQt|bin|lxqt-session"
        "LXDE|bin|lxsession"
        "i3|bin|i3"
        "Sway|bin|sway"
        "DWM|bin|dwm"
        "Awesome|bin|awesome"
        "BSPWM|bin|bspwm"
        "Openbox|bin|openbox"
        "Fluxbox|bin|fluxbox"
    )

    INSTALLED_DESKTOPS=()
    for entry in "${DE_LIST[@]}"; do
        IFS='|' read -r name type value <<< "$entry"
        if is_installed "$PACKAGER" "$type" "$value"; then
            INSTALLED_DESKTOPS+=("$name")
        fi
        unset IFS
    done

    if [ ${#INSTALLED_DESKTOPS[@]} -eq 0 ]; then
        echo "No supported desktop environments or window managers detected as installed."
        exit 0
    fi

    # Show menu
    echo "Select the desktop environment or window manager to uninstall:"
    for i in "${!INSTALLED_DESKTOPS[@]}"; do
        idx=$((i+1))
        echo "$idx) ${INSTALLED_DESKTOPS[$i]}"
    done
    echo "q) Quit"

    read -p "Enter your choice: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#INSTALLED_DESKTOPS[@]} ]; then
        selected_de="${INSTALLED_DESKTOPS[$((choice-1))]}"
        uninstall_desktop "$PACKAGER" "$selected_de"
        echo "Uninstallation complete. You may need to reboot your system."
        exit 0
    elif [[ "$choice" =~ ^[qQ]$ ]]; then
        echo "Exiting..."
        exit 0
    else
        echo "Invalid choice"
        exit 1
    fi
}


checkEnv
main