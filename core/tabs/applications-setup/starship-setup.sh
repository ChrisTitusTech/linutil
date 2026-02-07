#!/bin/sh -e

. ../common-script.sh

STARSHIP_BIN="$HOME/.local/bin/starship"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
LINUTIL_UNINSTALL_SUPPORTED=1

installStarship() {
    if command_exists starship; then
        printf "%b\n" "${GREEN}Starship is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Starship...${RC}"

    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile install nixpkgs#starship
        return 0
    fi

    case "$PACKAGER" in
        apt-get|nala|dnf|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y starship
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm starship
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add starship
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy starship
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y starship
            ;;
        flatpak)
            curl -sSL https://starship.rs/install.sh | "$ESCALATION_TOOL" sh -s -- -y
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

uninstallStarship() {
    printf "%b\n" "${YELLOW}Uninstalling Starship...${RC}"
    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile remove nixpkgs#starship || true
    else
        uninstall_native starship || true
    fi

    if [ -f "$STARSHIP_BIN" ]; then
        rm -f "$STARSHIP_BIN"
    fi

    if [ -f "$STARSHIP_CONFIG" ] && [ -f "${STARSHIP_CONFIG}.bak" ]; then
        rm -f "$STARSHIP_CONFIG"
        restore_file_backup "$STARSHIP_CONFIG"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallStarship
else
    backup_file "$STARSHIP_CONFIG"
    installStarship
fi
