#!/bin/sh -e

. ../common-script.sh

checkDE() {
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        case "$XDG_CURRENT_DESKTOP" in
            *GNOME*)
                DE="GNOME"
                ;;
            *KDE*)
                DE="KDE"
                ;;
        esac
    fi
}

installExtra() {
    if [ "$PACKAGER" = "apt-get" ] || [ "$PACKAGER" = "nala" ]; then
        checkDE
        # Only used for Ubuntu GNOME. Ubuntu GNOME doesnt allow flathub to be added as a remote to their store.
        # So in case the user wants to use a GUI software manager they can setup it here
        if [ "$DE" = "GNOME" ]; then
            printf "%b" "${YELLOW}Detected GNOME desktop environment. Would you like to install GNOME Software plugin for Flatpak? (y/N): ${RC}"
            read -r install_gnome
            if [ "$install_gnome" = "y" ] || [ "$install_gnome" = "Y" ]; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnome-software-plugin-flatpak
            fi
        # Useful for Debian KDE spin as well
        elif [ "$DE" = "KDE" ]; then
            printf "%b" "${YELLOW}Detected KDE desktop environment. Would you like to install KDE Plasma Discover backend for Flatpak? (y/N): ${RC}"
            read -r install_kde
            if [ "$install_kde" = "y" ] || [ "$install_kde" = "Y" ]; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y plasma-discover-backend-flatpak
            fi
        fi
    fi
}

checkEnv
checkEscalationTool
checkFlatpak
installExtra