#!/bin/sh -e

. ../../common-script.sh

installDiskUsage() {
    if ! flatpak_app_installed org.gnome.baobab && ! command_exists baobab; then
        printf "%b\n" "${YELLOW}Installing GNOME Disk Usage Analyzer...${RC}"
        if try_flatpak_install org.gnome.baobab; then
            return 0
        fi
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            nix profile install nixpkgs#baobab
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y baobab
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm baobab
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add baobab
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy baobab
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y baobab
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
        printf "%b\n" "${GREEN}GNOME Disk Usage Analyzer is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installDiskUsage
