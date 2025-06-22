#!/bin/sh -e

. ../common-script.sh

# Install packages with privilege handling
install_packages() {
    pkg_manager=$1
    shift
    # shellcheck disable=SC2086
    case $pkg_manager in
        paru|yay)
            $pkg_manager -S --needed --noconfirm "$@"
            ;;
        pacman)
            $ESCALATION_TOOL $pkg_manager -S --needed --noconfirm "$@"
            ;;
        apt-get|nala|dnf|zypper)
            $ESCALATION_TOOL $pkg_manager install -y "$@"
            ;;
    esac
}

installDesktopEnvironment() {
    printf "%s\n" "$YELLOW Installing Desktop Environment... $RC"
    case "$PACKAGER" in
        pacman)
            case "$1" in
                gnome)      install_packages "$AUR_HELPER" gnome gnome-extra ;;
                kde)        install_packages "$AUR_HELPER" plasma kde-applications ;;
                xfce)       install_packages "$AUR_HELPER" xfce4 xfce4-goodies ;;
                cinnamon)   install_packages "$AUR_HELPER" cinnamon cinnamon-translations ;;
                mate)       install_packages "$AUR_HELPER" mate mate-extra ;;
                budgie)     install_packages "$AUR_HELPER" budgie-desktop ;;
                lxqt)       install_packages "$AUR_HELPER" lxqt ;;
                lxde)       install_packages "$AUR_HELPER" lxde ;;
                *) printf "%s\n" "$RED Unsupported desktop environment: $1 $RC"; exit 1 ;;
            esac
            ;;
        apt-get|nala)
            case "$1" in
                gnome)      install_packages "$PACKAGER" ubuntu-gnome-desktop ;;
                kde)        install_packages "$PACKAGER" kde-plasma-desktop ;;
                xfce)       install_packages "$PACKAGER" xfce4 xfce4-goodies ;;
                cinnamon)   install_packages "$PACKAGER" cinnamon-desktop-environment ;;
                mate)       install_packages "$PACKAGER" ubuntu-mate-desktop ;;
                budgie)     install_packages "$PACKAGER" ubuntu-budgie-desktop ;;
                lxqt)       install_packages "$PACKAGER" lubuntu-desktop ;;
                lxde)       install_packages "$PACKAGER" lxde ;;
                *) printf "%s\n" "$RED Unsupported desktop environment: $1 $RC"; exit 1 ;;
            esac
            ;;
        dnf)
            case "$1" in
                gnome)      install_packages "$PACKAGER" @gnome-desktop ;;
                kde)        install_packages "$PACKAGER" @kde-desktop ;;
                xfce)       install_packages "$PACKAGER" @xfce-desktop-environment ;;
                cinnamon)   install_packages "$PACKAGER" @cinnamon-desktop-environment ;;
                mate)       install_packages "$PACKAGER" @mate-desktop-environment ;;
                budgie)     install_packages "$PACKAGER" @budgie-desktop-environment ;;
                lxqt)       install_packages "$PACKAGER" @lxqt-desktop-environment ;;
                lxde)       install_packages "$PACKAGER" @lxde-desktop-environment ;;
                *) printf "%s\n" "$RED Unsupported desktop environment: $1 $RC"; exit 1 ;;
            esac
            ;;
        zypper)
            case "$1" in
                gnome)      install_packages "$PACKAGER" patterns-gnome-gnome ;;
                kde)        install_packages "$PACKAGER" patterns-kde-kde_plasma ;;
                xfce)       install_packages "$PACKAGER" patterns-xfce-xfce ;;
                cinnamon)   install_packages "$PACKAGER" patterns-cinnamon-cinnamon ;;
                mate)       install_packages "$PACKAGER" patterns-mate-mate ;;
                budgie)     install_packages "$PACKAGER" patterns-budgie-budgie ;;
                lxqt)       install_packages "$PACKAGER" patterns-lxqt-lxqt ;;
                lxde)       install_packages "$PACKAGER" patterns-lxde-lxde ;;
                *) printf "%s\n" "$RED Unsupported desktop environment: $1 $RC"; exit 1 ;;
            esac
            ;;
        *)
            printf "%s\n" "$RED Unsupported package manager: $PACKAGER $RC"
            exit 1
            ;;
    esac
}

installWindowManager() {
    printf "%s\n" "$YELLOW Installing Window Manager... $RC"
    case "$PACKAGER" in
        pacman)
            case "$1" in
                i3)         install_packages "$AUR_HELPER" i3-wm i3status i3lock ;;
                sway)       install_packages "$AUR_HELPER" sway swaylock swayidle ;;
                dwm)        install_packages "$AUR_HELPER" dwm ;;
                awesome)    install_packages "$AUR_HELPER" awesome ;;
                bspwm)      install_packages "$AUR_HELPER" bspwm sxhkd ;;
                openbox)    install_packages "$AUR_HELPER" openbox ;;
                fluxbox)    install_packages "$AUR_HELPER" fluxbox ;;
                *) printf "%s\n" "$RED Unsupported window manager: $1 $RC"; exit 1 ;;
            esac
            ;;
        apt-get|nala|dnf|zypper)
            case "$1" in
                i3)         install_packages "$PACKAGER" i3 i3status i3lock ;;
                sway)       install_packages "$PACKAGER" sway swaylock swayidle ;;
                dwm)        install_packages "$PACKAGER" dwm ;;
                awesome)    install_packages "$PACKAGER" awesome ;;
                bspwm)      install_packages "$PACKAGER" bspwm sxhkd ;;
                openbox)    install_packages "$PACKAGER" openbox ;;
                fluxbox)    install_packages "$PACKAGER" fluxbox ;;
                *) printf "%s\n" "$RED Unsupported window manager: $1 $RC"; exit 1 ;;
            esac
            ;;
        *)
            printf "%s\n" "$RED Unsupported package manager: $PACKAGER $RC"
            exit 1
            ;;
    esac
}

main() {
    printf "%s\n" "$YELLOW Desktop Environment and Window Manager Installation $RC"
    printf "%s\n" "$YELLOW ============================================= $RC"
    printf "%s\n" "$YELLOW 1. Install Desktop Environment $RC"
    printf "%s\n" "$YELLOW 2. Install Window Manager $RC"
    printf "%s\n" "$YELLOW 3. Exit $RC"
    printf "%s" "$YELLOW Please select an option (1-3): $RC"
    read choice

    case "$choice" in
        1)
            printf "%s\n" "$YELLOW Available Desktop Environments: $RC"
            printf "%s\n" "$YELLOW 1. GNOME $RC"
            printf "%s\n" "$YELLOW 2. KDE Plasma $RC"
            printf "%s\n" "$YELLOW 3. XFCE $RC"
            printf "%s\n" "$YELLOW 4. Cinnamon $RC"
            printf "%s\n" "$YELLOW 5. MATE $RC"
            printf "%s\n" "$YELLOW 6. Budgie $RC"
            printf "%s\n" "$YELLOW 7. LXQt $RC"
            printf "%s\n" "$YELLOW 8. LXDE $RC"
            printf "%s" "$YELLOW Please select a desktop environment (1-8): $RC"
            read de_choice
            case "$de_choice" in
                1) installDesktopEnvironment gnome ;;
                2) installDesktopEnvironment kde ;;
                3) installDesktopEnvironment xfce ;;
                4) installDesktopEnvironment cinnamon ;;
                5) installDesktopEnvironment mate ;;
                6) installDesktopEnvironment budgie ;;
                7) installDesktopEnvironment lxqt ;;
                8) installDesktopEnvironment lxde ;;
                *) printf "%s\n" "$RED Invalid selection $RC" ;;
            esac
            ;;
        2)
            printf "%s\n" "$YELLOW Available Window Managers: $RC"
            printf "%s\n" "$YELLOW 1. i3 $RC"
            printf "%s\n" "$YELLOW 2. Sway $RC"
            printf "%s\n" "$YELLOW 3. DWM $RC"
            printf "%s\n" "$YELLOW 4. Awesome $RC"
            printf "%s\n" "$YELLOW 5. BSPWM $RC"
            printf "%s\n" "$YELLOW 6. Openbox $RC"
            printf "%s\n" "$YELLOW 7. Fluxbox $RC"
            printf "%s" "$YELLOW Please select a window manager (1-7): $RC"
            read wm_choice
            case "$wm_choice" in
                1) installWindowManager i3 ;;
                2) installWindowManager sway ;;
                3) installWindowManager dwm ;;
                4) installWindowManager awesome ;;
                5) installWindowManager bspwm ;;
                6) installWindowManager openbox ;;
                7) installWindowManager fluxbox ;;
                *) printf "%s\n" "$RED Invalid selection $RC" ;;
            esac
            ;;
        3)
            exit 0
            ;;
        *)
            printf "%s\n" "$RED Invalid selection $RC"
            ;;
    esac
}

checkEnv
main
