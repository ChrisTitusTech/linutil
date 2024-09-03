#!/bin/sh -e

. ../common-script.sh

setuplact() {
    echo "Installing Lact"
    if command_exists lact; then
        echo "Lact is already installed."
        return
    fi
    checkAURHelper
    $AUR_HELPER -S --noconfirm lact
    if command_exists systemctl; then
       $ESCALATION_TOOL systemctl enable --now lactd
    fi

}

checkEnv
checkEscalationTool
setuplact
