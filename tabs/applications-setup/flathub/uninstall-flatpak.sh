#!/bin/sh -e

. ../../common-script.sh

# Used to detect the desktop environment, Only used for the If statement in the uninstall_flatpak function.
# Perhaps this should be moved to common-script.sh later on?
detect_de() {
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

# Uninstall Flatpak if installed.
uninstall_flatpak() {
    printf "%b\n" "${RED}Are you sure you want to uninstall Flatpak and remove Flathub remote? (y/n)${RC}"
    read confirm_uninstall
    if [ "$confirm_uninstall" != "y" ] && [ "$confirm_uninstall" != "Y" ]; then
        printf "%b\n" "${GREEN}Uninstallation cancelled.${RC}"
        exit 0
    fi

    if command_exists flatpak; then
        printf "%b\n" "${RED}Uninstalling Flatpak...${RC}"
        case "$PACKAGER" in
            pacman)
                $ESCALATION_TOOL "$PACKAGER" -Rns --noconfirm flatpak
                ;;
            apt-get|nala)
                $ESCALATION_TOOL "$PACKAGER" remove -y flatpak
                ;;
            dnf)
                $ESCALATION_TOOL "$PACKAGER" remove -y flatpak
                ;;
            zypper)
                $ESCALATION_TOOL "$PACKAGER" remove -y flatpak
                ;;
            yum)
                $ESCALATION_TOOL "$PACKAGER" remove -y flatpak
                ;;
            xbps-remove)
                $ESCALATION_TOOL "$PACKAGER" remove -R flatpak
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
                exit 1
                ;;
        esac
        printf "%b\n" "Removing Flathub remote..."
        $ESCALATION_TOOL flatpak remote-delete flathub
    else
        printf "%b\n" "${GREEN}Flatpak is not installed. Nothing to do.${RC}"
    fi

    if [ "$PACKAGER" = "apt-get" ] || [ "$PACKAGER" = "nala" ]; then
        detect_de
        if [ "$DE" = "GNOME" ]; then
            printf "%b\n" "${YELLOW}Detected GNOME desktop environment. Would you like to uninstall GNOME Software plugin for Flatpak? (y/n)${RC}"
            read uninstall_gnome
            if [ "$uninstall_gnome" = "y" ] || [ "$uninstall_gnome" = "Y" ]; then
                $ESCALATION_TOOL "$PACKAGER" remove -y gnome-software-plugin-flatpak
            fi
        elif [ "$DE" = "KDE" ]; then
            printf "%b\n" "${YELLOW}Detected KDE desktop environment. Would you like to uninstall KDE Plasma Discover backend for Flatpak? (y/n)${RC}"
            read uninstall_kde
            if [ "$uninstall_kde" = "y" ] || [ "$uninstall_kde" = "Y" ]; then
                $ESCALATION_TOOL "$PACKAGER" remove -y plasma-discover-backend-flatpak
            fi
        fi
    fi
}

checkEnv
checkEscalationTool
uninstall_flatpak
