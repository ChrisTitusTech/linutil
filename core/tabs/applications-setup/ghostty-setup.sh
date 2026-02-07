#!/bin/sh -e

. ../common-script.sh

APP_FLATPAK_ID="com.mitchellh.ghostty"
LINUTIL_UNINSTALL_SUPPORTED=1

installGhostty() {
    if ! command_exists ghostty; then
    printf "%b\n" "${YELLOW}Installing Ghostty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ghostty
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add ghostty
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy ghostty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ghostty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Ghostty is already installed.${RC}"
    fi
}

setupGhosttyConfig() {
    printf "%b\n" "${YELLOW}Copying ghostty config files...${RC}"
    backup_dir "${HOME}/.config/ghostty"
    backup_file "${HOME}/.config/ghostty/config"
    mkdir -p "${HOME}/.config/ghostty/"
    curl -sSLo "${HOME}/.config/ghostty/config" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/ghostty/config"
    printf "%b\n" "${GREEN}Ghostty configuration files copied.${RC}"
}

uninstallGhostty() {
    printf "%b\n" "${YELLOW}Uninstalling Ghostty...${RC}"
    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile remove nixpkgs#ghostty || true
    else
        uninstall_flatpak_app "$APP_FLATPAK_ID" || uninstall_native ghostty || true
    fi
    if [ -d "${HOME}/.config/ghostty-bak" ]; then
        restore_dir_backup "${HOME}/.config/ghostty"
    else
        restore_file_backup "${HOME}/.config/ghostty/config"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallGhostty
else
    installGhostty
    setupGhosttyConfig
fi
