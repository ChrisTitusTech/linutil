#!/bin/sh -e

. ../../common-script.sh

installCalculator() {
    if ! flatpak_app_installed org.gnome.Calculator && ! command_exists gnome-calculator; then
        printf "%b\n" "${YELLOW}Installing GNOME Calculator...${RC}"
        if try_flatpak_install org.gnome.Calculator; then
            return 0
        fi
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            nix profile install nixpkgs#gnome-calculator
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnome-calculator
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gnome-calculator
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add gnome-calculator
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy gnome-calculator
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnome-calculator
                ;;
            flatpak)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}GNOME Calculator is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installCalculator
