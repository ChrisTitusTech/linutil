#!/bin/sh -e

. ../../common-script.sh

installDisks() {
    if ! flatpak_app_installed org.gnome.DiskUtility && ! command_exists gnome-disks; then
        printf "%b\n" "${YELLOW}Installing GNOME Disks...${RC}"
        if try_flatpak_install org.gnome.DiskUtility; then
            return 0
        fi
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
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}GNOME Disks is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installDisks
