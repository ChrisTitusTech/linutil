#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.gnome.Loupe"
APP_UNINSTALL_PKGS="GNOME Image Viewer eog nixpkgs"


installImageViewer() {
    if ! flatpak_app_installed org.gnome.Loupe && ! command_exists loupe && ! command_exists eog && ! flatpak_app_installed org.gnome.eog; then
        printf "%b\n" "${YELLOW}Installing GNOME Image Viewer...${RC}"
        if try_flatpak_install org.gnome.Loupe; then
            return 0
        fi
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            if nix profile install nixpkgs#loupe; then
                return 0
            fi
        fi
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y eog
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm eog
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add eog
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy eog
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y eog
                ;;
            flatpak)
                ;;
            *)
                ;;
        esac
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            if nix profile install nixpkgs#eog; then
                return 0
            fi
        fi
        if ! command_exists eog && ! flatpak_app_installed org.gnome.eog; then
            if try_flatpak_install org.gnome.eog; then
                return 0
            fi
        fi
        printf "%b\n" "${RED}Failed to install GNOME Image Viewer (Loupe/EOG).${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}GNOME Image Viewer is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installImageViewer
