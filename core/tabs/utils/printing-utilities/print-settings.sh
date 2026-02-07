#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1

installPrintSettings() {
    if ! command_exists system-config-printer; then
        printf "%b\n" "${YELLOW}Installing Printer Settings...${RC}"
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            nix profile install nixpkgs#system-config-printer
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y system-config-printer
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm system-config-printer
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add system-config-printer
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy system-config-printer
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y system-config-printer
                ;;
            flatpak)
                printf "%b\n" "${RED}No Flatpak build is known for Printer Settings; native packages are required.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Printer Settings is already installed.${RC}"
    fi
}

uninstallPrintSettings() {
    printf "%b\n" "${YELLOW}Uninstalling Printer Settings...${RC}"
    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile remove nixpkgs#system-config-printer || true
        return 0
    fi
    uninstall_native system-config-printer || true
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallPrintSettings
else
    installPrintSettings
fi
