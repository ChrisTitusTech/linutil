#!/bin/sh -e

. ../common-script.sh

setuplact() {
    echo "Installing Lact"

    if command_exists lact; then
        echo "Lact is already installed."
        return
    fi

    checkAURHelper  # Ensure we have an AUR helper available

    if [ -z "$AUR_HELPER" ]; then
        echo -e "${RED}No suitable AUR helper found to install Lact!${RC}"
        exit 1
    fi

    echo "Using AUR helper: ${AUR_HELPER}"
    $AUR_HELPER -S --noconfirm lact
    sudo systemctl enable --now lactd
}

checkEnv
setuplact
