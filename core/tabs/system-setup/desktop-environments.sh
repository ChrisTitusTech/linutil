#!/bin/sh -e

. ../common-script.sh

# Function to detect AUR helper
detect_aur_helper() {
    if command -v paru &> /dev/null; then
        echo "paru"
    elif command -v yay &> /dev/null; then
        echo "yay"
    else
        echo "pacman"
    fi
}

# Function to install packages with proper privilege handling
install_packages() {
    local pkg_manager=$1
    shift
    local packages=("$@")
    
    case $pkg_manager in
        "paru"|"yay")
            "$pkg_manager" -S --needed --noconfirm "${packages[@]}"
            ;;
        "pacman")
            "$ESCALATION_TOOL" "$pkg_manager" -S --needed --noconfirm "${packages[@]}"
            ;;
        "apt-get"|"nala")
            "$ESCALATION_TOOL" "$pkg_manager" install -y "${packages[@]}"
            ;;
        "dnf")
            "$ESCALATION_TOOL" "$pkg_manager" install -y "${packages[@]}"
            ;;
        "zypper")
            "$ESCALATION_TOOL" "$pkg_manager" install -y "${packages[@]}"
            ;;
    esac
}

installDesktopEnvironment() {
    printf "%b\n" "${YELLOW}Installing Desktop Environment...${RC}"
    case "$PACKAGER" in
        pacman)
            local aur_helper=$(detect_aur_helper)
            case "$1" in
                "gnome")
                    install_packages "$aur_helper" "gnome" "gnome-extra"
                    ;;
                "kde")
                    install_packages "$aur_helper" "plasma" "kde-applications"
                    ;;
                "xfce")
                    install_packages "$aur_helper" "xfce4" "xfce4-goodies"
                    ;;
                "cinnamon")
                    install_packages "$aur_helper" "cinnamon" "cinnamon-translations"
                    ;;
                "mate")
                    install_packages "$aur_helper" "mate" "mate-extra"
                    ;;
                "budgie")
                    install_packages "$aur_helper" "budgie-desktop"
                    ;;
                "lxqt")
                    install_packages "$aur_helper" "lxqt"
                    ;;
                "lxde")
                    install_packages "$aur_helper" "lxde"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported desktop environment: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        apt-get|nala)
            case "$1" in
                "gnome")
                    install_packages "$PACKAGER" "ubuntu-gnome-desktop"
                    ;;
                "kde")
                    install_packages "$PACKAGER" "kde-plasma-desktop"
                    ;;
                "xfce")
                    install_packages "$PACKAGER" "xfce4" "xfce4-goodies"
                    ;;
                "cinnamon")
                    install_packages "$PACKAGER" "cinnamon-desktop-environment"
                    ;;
                "mate")
                    install_packages "$PACKAGER" "ubuntu-mate-desktop"
                    ;;
                "budgie")
                    install_packages "$PACKAGER" "ubuntu-budgie-desktop"
                    ;;
                "lxqt")
                    install_packages "$PACKAGER" "lubuntu-desktop"
                    ;;
                "lxde")
                    install_packages "$PACKAGER" "lxde"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported desktop environment: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        dnf)
            case "$1" in
                "gnome")
                    install_packages "$PACKAGER" "@gnome-desktop"
                    ;;
                "kde")
                    install_packages "$PACKAGER" "@kde-desktop"
                    ;;
                "xfce")
                    install_packages "$PACKAGER" "@xfce-desktop-environment"
                    ;;
                "cinnamon")
                    install_packages "$PACKAGER" "@cinnamon-desktop-environment"
                    ;;
                "mate")
                    install_packages "$PACKAGER" "@mate-desktop-environment"
                    ;;
                "budgie")
                    install_packages "$PACKAGER" "@budgie-desktop-environment"
                    ;;
                "lxqt")
                    install_packages "$PACKAGER" "@lxqt-desktop-environment"
                    ;;
                "lxde")
                    install_packages "$PACKAGER" "@lxde-desktop-environment"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported desktop environment: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        zypper)
            case "$1" in
                "gnome")
                    install_packages "$PACKAGER" "patterns-gnome-gnome"
                    ;;
                "kde")
                    install_packages "$PACKAGER" "patterns-kde-kde_plasma"
                    ;;
                "xfce")
                    install_packages "$PACKAGER" "patterns-xfce-xfce"
                    ;;
                "cinnamon")
                    install_packages "$PACKAGER" "patterns-cinnamon-cinnamon"
                    ;;
                "mate")
                    install_packages "$PACKAGER" "patterns-mate-mate"
                    ;;
                "budgie")
                    install_packages "$PACKAGER" "patterns-budgie-budgie"
                    ;;
                "lxqt")
                    install_packages "$PACKAGER" "patterns-lxqt-lxqt"
                    ;;
                "lxde")
                    install_packages "$PACKAGER" "patterns-lxde-lxde"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported desktop environment: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
}

installWindowManager() {
    printf "%b\n" "${YELLOW}Installing Window Manager...${RC}"
    case "$PACKAGER" in
        pacman)
            local aur_helper=$(detect_aur_helper)
            case "$1" in
                "i3")
                    install_packages "$aur_helper" "i3-wm" "i3status" "i3lock"
                    ;;
                "sway")
                    install_packages "$aur_helper" "sway" "swaylock" "swayidle"
                    ;;
                "dwm")
                    install_packages "$aur_helper" "dwm"
                    ;;
                "awesome")
                    install_packages "$aur_helper" "awesome"
                    ;;
                "bspwm")
                    install_packages "$aur_helper" "bspwm" "sxhkd"
                    ;;
                "openbox")
                    install_packages "$aur_helper" "openbox"
                    ;;
                "fluxbox")
                    install_packages "$aur_helper" "fluxbox"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported window manager: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        apt-get|nala)
            case "$1" in
                "i3")
                    install_packages "$PACKAGER" "i3" "i3status" "i3lock"
                    ;;
                "sway")
                    install_packages "$PACKAGER" "sway" "swaylock" "swayidle"
                    ;;
                "dwm")
                    install_packages "$PACKAGER" "dwm"
                    ;;
                "awesome")
                    install_packages "$PACKAGER" "awesome"
                    ;;
                "bspwm")
                    install_packages "$PACKAGER" "bspwm" "sxhkd"
                    ;;
                "openbox")
                    install_packages "$PACKAGER" "openbox"
                    ;;
                "fluxbox")
                    install_packages "$PACKAGER" "fluxbox"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported window manager: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        dnf)
            case "$1" in
                "i3")
                    install_packages "$PACKAGER" "i3" "i3status" "i3lock"
                    ;;
                "sway")
                    install_packages "$PACKAGER" "sway" "swaylock" "swayidle"
                    ;;
                "dwm")
                    install_packages "$PACKAGER" "dwm"
                    ;;
                "awesome")
                    install_packages "$PACKAGER" "awesome"
                    ;;
                "bspwm")
                    install_packages "$PACKAGER" "bspwm" "sxhkd"
                    ;;
                "openbox")
                    install_packages "$PACKAGER" "openbox"
                    ;;
                "fluxbox")
                    install_packages "$PACKAGER" "fluxbox"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported window manager: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        zypper)
            case "$1" in
                "i3")
                    install_packages "$PACKAGER" "i3" "i3status" "i3lock"
                    ;;
                "sway")
                    install_packages "$PACKAGER" "sway" "swaylock" "swayidle"
                    ;;
                "dwm")
                    install_packages "$PACKAGER" "dwm"
                    ;;
                "awesome")
                    install_packages "$PACKAGER" "awesome"
                    ;;
                "bspwm")
                    install_packages "$PACKAGER" "bspwm" "sxhkd"
                    ;;
                "openbox")
                    install_packages "$PACKAGER" "openbox"
                    ;;
                "fluxbox")
                    install_packages "$PACKAGER" "fluxbox"
                    ;;
                *)
                    printf "%b\n" "${RED}Unsupported window manager: $1${RC}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
}

main() {
    printf "%b\n" "${YELLOW}Desktop Environment and Window Manager Installation${RC}"
    printf "%b\n" "${YELLOW}=============================================${RC}"
    printf "%b\n" "${YELLOW}1. Install Desktop Environment${RC}"
    printf "%b\n" "${YELLOW}2. Install Window Manager${RC}"
    printf "%b\n" "${YELLOW}3. Exit${RC}"
    printf "%b" "${YELLOW}Please select an option (1-3): ${RC}"
    read -r choice

    case "$choice" in
        1)
            printf "%b\n" "${YELLOW}Available Desktop Environments:${RC}"
            printf "%b\n" "${YELLOW}1. GNOME${RC}"
            printf "%b\n" "${YELLOW}2. KDE Plasma${RC}"
            printf "%b\n" "${YELLOW}3. XFCE${RC}"
            printf "%b\n" "${YELLOW}4. Cinnamon${RC}"
            printf "%b\n" "${YELLOW}5. MATE${RC}"
            printf "%b\n" "${YELLOW}6. Budgie${RC}"
            printf "%b\n" "${YELLOW}7. LXQt${RC}"
            printf "%b\n" "${YELLOW}8. LXDE${RC}"
            printf "%b" "${YELLOW}Please select a desktop environment (1-8): ${RC}"
            read -r de_choice

            case "$de_choice" in
                1) installDesktopEnvironment "gnome" ;;
                2) installDesktopEnvironment "kde" ;;
                3) installDesktopEnvironment "xfce" ;;
                4) installDesktopEnvironment "cinnamon" ;;
                5) installDesktopEnvironment "mate" ;;
                6) installDesktopEnvironment "budgie" ;;
                7) installDesktopEnvironment "lxqt" ;;
                8) installDesktopEnvironment "lxde" ;;
                *) printf "%b\n" "${RED}Invalid selection${RC}" ;;
            esac
            ;;
        2)
            printf "%b\n" "${YELLOW}Available Window Managers:${RC}"
            printf "%b\n" "${YELLOW}1. i3${RC}"
            printf "%b\n" "${YELLOW}2. Sway${RC}"
            printf "%b\n" "${YELLOW}3. DWM${RC}"
            printf "%b\n" "${YELLOW}4. Awesome${RC}"
            printf "%b\n" "${YELLOW}5. BSPWM${RC}"
            printf "%b\n" "${YELLOW}6. Openbox${RC}"
            printf "%b\n" "${YELLOW}7. Fluxbox${RC}"
            printf "%b" "${YELLOW}Please select a window manager (1-7): ${RC}"
            read -r wm_choice

            case "$wm_choice" in
                1) installWindowManager "i3" ;;
                2) installWindowManager "sway" ;;
                3) installWindowManager "dwm" ;;
                4) installWindowManager "awesome" ;;
                5) installWindowManager "bspwm" ;;
                6) installWindowManager "openbox" ;;
                7) installWindowManager "fluxbox" ;;
                *) printf "%b\n" "${RED}Invalid selection${RC}" ;;
            esac
            ;;
        3)
            exit 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid selection${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
main 