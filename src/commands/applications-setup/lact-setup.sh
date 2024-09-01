#!/bin/sh -e

. ../common-script.sh

setuplact() {
    echo "Installing Lact"

    if command_exists lact; then
        echo "Lact is already installed."
        return
    fi

    checkAURHelper

    for helper in yay paru trizen; do
        if command_exists "${helper}"; then
            echo "Using AUR helper: ${helper}"
            ${helper} -S --noconfirm lact
            sudo systemctl enable --now lactd
            return
        fi
    done

    echo -e "${RED}No suitable AUR helper found to install Lact!${RC}"
    exit 1
}

checkEnv
setuplact
