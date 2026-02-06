#!/bin/sh -e

. ../common-script.sh

APP_FLATPAK_ID="net.kovidgoyal.kitty"
LINUTIL_UNINSTALL_SUPPORTED=1

installKitty() {
    if ! command_exists kitty; then
        printf "%b\n" "${YELLOW}Installing Kitty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm kitty
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add kitty
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy kitty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y kitty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
    fi
}

setupKittyConfig() {
    printf "%b\n" "${YELLOW}Copying Kitty configuration files...${RC}"
    backup_dir "${HOME}/.config/kitty"
    backup_file "${HOME}/.config/kitty/kitty.conf"
    mkdir -p "${HOME}/.config/kitty/"
    curl -sSLo "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    curl -sSLo "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

uninstallKitty() {
    printf "%b\n" "${YELLOW}Uninstalling Kitty...${RC}"
    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile remove nixpkgs#kitty || true
    else
        uninstall_flatpak_app "$APP_FLATPAK_ID" || uninstall_native kitty || true
    fi
    if [ -d "${HOME}/.config/kitty-bak" ]; then
        restore_dir_backup "${HOME}/.config/kitty"
    else
        restore_file_backup "${HOME}/.config/kitty/kitty.conf"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallKitty
else
    installKitty
    setupKittyConfig
fi
