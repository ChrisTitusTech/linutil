#!/bin/sh -e

. ../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1

installDisks() {
    if ! flatpak_app_installed org.gnome.DiskUtility && ! command_exists gnome-disks; then
        printf "%b\n" "${YELLOW}Installing GNOME Disks...${RC}"
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            nix profile install nixpkgs#gnome-disk-utility
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnome-disk-utility
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gnome-disk-utility
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add gnome-disk-utility
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy gnome-disk-utility
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnome-disk-utility
                ;;
            flatpak)
                printf "%b\n" "${YELLOW}Flatpak-only environment detected. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists gnome-disks; then
            return 0
        fi
        if try_flatpak_install org.gnome.DiskUtility; then
            return 0
        fi
        printf "%b\n" "${RED}Failed to install GNOME Disks.${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}GNOME Disks is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_flatpak_if_installed org.gnome.DiskUtility || true
    uninstall_native gnome-disk-utility || true
else
    installDisks
fi
