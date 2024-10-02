#!/bin/sh -e

. ../common-script.sh

themeinstall(){
    mkdir -p "$HOME/.local/share"
    cd "$HOME/.local/share"
    if [ -d 'Top-5-Bootloader-Themes' ]; then
        mv 'Top-5-Bootloader-Themes' 'Top-5-Bootloader-Themes.bak'
    fi
    git clone "https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes"
    cd "$HOME/.local/share/Top-5-Bootloader-Themes"
    "$ESCALATION_TOOL" ./install.sh
}

checkEnv
checkEscalationTool
themeinstall
