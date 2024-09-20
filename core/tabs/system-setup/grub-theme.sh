#!/bin/sh -e
. ../common-script.sh

themeinstall(){
    mkdir -p "$HOME/.local/share"
    cd "$HOME/.local/share" && git clone "https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes"
    cd "$HOME/.local/share/Top-5-Bootloader-Themes"
    "$ESCALATION_TOOL" ./install.sh
}

checkEnv
checkEscalationTool
themeinstall
