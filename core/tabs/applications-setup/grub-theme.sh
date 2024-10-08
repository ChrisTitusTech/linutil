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
}

checkEnv
checkEscalationTool
themeinstall
