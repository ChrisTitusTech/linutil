#!/bin/sh -e

. ../common-script.sh

# Used to detect the desktop environment, Only used for the If statement in the setup_flatpak function.
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

# Install Flatpak if not already installed.
setup_flatpak() {
    if ! command_exists flatpak; then
    printf "%b\n" "${YELLOW}Installing Flatpak...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm flatpak
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flatpak
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flatpak # Fedora should have flatpak already installed, this is just a failsafe
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flatpak
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" install -S flatpak
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: "$PACKAGER"${RC}"
                exit 1
                ;;
        esac
        printf "%b\n" "Adding Flathub remote..."
        "$ESCALATION_TOOL" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
        if command -v flatpak >/dev/null 2>&1; then
            if ! flatpak remotes | grep -q "flathub"; then
                printf "%b\n" "${YELLOW}Detected Flatpak package manager but Flathub remote is not added. Would you like to add it? (y/n)${RC}"
                read -r add_remote
                case "$add_remote" in
                    [Yy]*)
                        printf "%b\n" "Adding Flathub remote..."
                        "$ESCALATION_TOOL" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                        ;;
                esac
            else
                # Needed mostly for systems without a polkit agent running (Error: updating: Unable to connect to system bus)
                printf "%b\n" "${GREEN}Flathub already setup. You can quit.${RC}"
            fi
        fi
    fi

    if [ "$PACKAGER" = "apt-get" ] || [ "$PACKAGER" = "nala" ]; then
        detect_de
        # Only used for Ubuntu GNOME. Ubuntu GNOME doesnt allow flathub to be added as a remote to their store.
        # So in case the user wants to use a GUI siftware manager they can setup it here
        if [ "$DE" = "GNOME" ]; then
            printf "%b\n" "${YELLOW}Detected GNOME desktop environment. Would you like to install GNOME Software plugin for Flatpak? (y/n)${RC}"
            read -r install_gnome
            if [ "$install_gnome" = "y" ] || [ "$install_gnome" = "Y" ]; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnome-software-plugin-flatpak
            fi
        # Useful for Debian KDE spin as well
        elif [ "$DE" = "KDE" ]; then
            printf "%b\n" "${YELLOW}Detected KDE desktop environment. Would you like to install KDE Plasma Discover backend for Flatpak? (y/n)${RC}"
            read -r install_kde
            if [ "$install_kde" = "y" ] || [ "$install_kde" = "Y" ]; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y plasma-discover-backend-flatpak
            fi
        fi
    fi
}

checkEnv
checkEscalationTool
setup_flatpak
