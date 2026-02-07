#!/bin/sh -e

. ../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1

installCalculator() {
    if ! flatpak_app_installed org.gnome.Calculator && ! command_exists gnome-calculator; then
        printf "%b\n" "${YELLOW}Installing GNOME Calculator...${RC}"
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
                printf "%b\n" "${YELLOW}Flatpak-only environment detected. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists gnome-calculator; then
            return 0
        fi
        if try_flatpak_install org.gnome.Calculator; then
            return 0
        fi
        printf "%b\n" "${RED}Failed to install GNOME Calculator.${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}GNOME Calculator is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_flatpak_if_installed org.gnome.Calculator || true
    uninstall_native gnome-calculator || true
else
    installCalculator
fi
