#!/bin/sh -e

. ../common-script.sh
LINUTIL_UNINSTALL_SUPPORTED=1

installRofi() {
    if ! command_exists rofi; then
    printf "%b\n" "${YELLOW}Installing Rofi...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm rofi
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add rofi
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy rofi  
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y rofi
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Rofi is already installed.${RC}"
    fi
}

setupRofiConfig() {
    printf "%b\n" "${YELLOW}Copying Rofi configuration files...${RC}"
    backup_dir "$HOME/.config/rofi"
    mkdir -p "$HOME/.config/rofi"
    curl -sSLo "$HOME/.config/rofi/powermenu.sh" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/powermenu.sh
    chmod +x "$HOME/.config/rofi/powermenu.sh"
    curl -sSLo "$HOME/.config/rofi/config.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/config.rasi
    mkdir -p "$HOME/.config/rofi/themes"
    curl -sSLo "$HOME/.config/rofi/themes/nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/nord.rasi
    curl -sSLo "$HOME/.config/rofi/themes/sidetab-nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/sidetab-nord.rasi
    curl -sSLo "$HOME/.config/rofi/themes/powermenu.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/powermenu.rasi
}

uninstallRofi() {
    printf "%b\n" "${YELLOW}Uninstalling Rofi...${RC}"
    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile remove nixpkgs#rofi || true
    else
        uninstall_native rofi || true
    fi
    restore_dir_backup "$HOME/.config/rofi"
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallRofi
else
    installRofi
    setupRofiConfig
fi
