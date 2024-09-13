#!/bin/sh -e
. ../common-script.sh

themeinstall(){
    cd "$HOME" && git clone "https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes"
    cd "Top-5-Bootloader-Themes"
    $ESCALATION_TOOL ./install.sh
}

checkEnv
checkEscalationTool
themeinstall