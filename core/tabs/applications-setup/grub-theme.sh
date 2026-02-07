#!/bin/sh -e

. ../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS=""


themeinstall(){
    mkdir -p "$HOME/.local/share"
    cd "$HOME/.local/share"
    if [ -d 'Top-5-Bootloader-Themes' ]; then
        rm -rf 'Top-5-Bootloader-Themes'
    fi
    git clone "https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes"
    cd "Top-5-Bootloader-Themes"
    "$ESCALATION_TOOL" ./install.sh
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


themeinstall
