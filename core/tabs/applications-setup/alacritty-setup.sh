#!/bin/sh -e

. ../common-script.sh

APP_FLATPAK_ID="org.alacritty.Alacritty"
LINUTIL_UNINSTALL_SUPPORTED=1

installAlacritty() {
    if ! command_exists alacritty; then
    printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm alacritty
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add alacritty
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy alacritty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y alacritty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Alacritty is already installed.${RC}"
    fi
}

setupAlacrittyConfig() {
    printf "%b\n" "${YELLOW}Copying alacritty config files...${RC}"
    backup_dir "${HOME}/.config/alacritty"
    backup_file "${HOME}/.config/alacritty/alacritty.toml"
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/keybinds.toml" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/alacritty/keybinds.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/alacritty/nordic.toml"
    printf "%b\n" "${GREEN}Alacritty configuration files copied.${RC}"
}

uninstallAlacritty() {
    printf "%b\n" "${YELLOW}Uninstalling Alacritty...${RC}"
    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile remove nixpkgs#alacritty || true
    else
        uninstall_flatpak_app "$APP_FLATPAK_ID" || uninstall_native alacritty || true
    fi
    if [ -d "${HOME}/.config/alacritty-bak" ]; then
        restore_dir_backup "${HOME}/.config/alacritty"
    else
        restore_file_backup "${HOME}/.config/alacritty/alacritty.toml"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallAlacritty
else
    installAlacritty
    setupAlacrittyConfig
fi
