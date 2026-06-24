#!/bin/sh -e

. ../common-script.sh

themeinstall(){
    mkdir -p "$HOME/.local/share"
    cd "$HOME/.local/share"
    if [ -d 'Top-5-Bootloader-Themes' ]; then
        rm -rf 'Top-5-Bootloader-Themes'
    fi
    git clone "https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes"
    cd "Top-5-Bootloader-Themes"
    "$ESCALATION_TOOL" ./install.sh
    if command -v grub-mkconfig >/dev/null 2>&1; then
        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    elif command -v grub2-mkconfig >/dev/null 2>&1; then
        "$ESCALATION_TOOL" grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
}

checkEnv
themeinstall
