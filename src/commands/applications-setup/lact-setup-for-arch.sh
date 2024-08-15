#!/bin/sh -e

. ./common-script.sh

setupLACT() {
    
    echo "Checking for rustup..."
    if ! command_exists rustup; then
        echo "rustup not found. Installing rustup..."
        sudo pacman -S --noconfirm rustup
    fi
    echo "Installing stable Rust toolchain..."
    rustup install stable
    rustup default stable

    echo "Installing LACT (Open Source AMD GPU OverClocking Tool)..."
    if ! command_exists lact; then
        case ${PACKAGER} in
            pacman)
                if ! command_exists paru && ! command_exists yay; then
                    echo "Neither paru nor yay is installed. Installing recommended AUR helper paru..."
                    sudo pacman-S --noconfirm --needed git base-devel
                    git clone https://aur.archlinux.org/paru.git
                    cd paru
                    makepkg -si
                    cd ..
                fi
                if command_exists paru; then
                    paru -S --noconfirm lact
                elif command_exists yay; then
                    yay -S --noconfirm lact
                else
                    echo "Failed to install an AUR helper. Please install LACT manually."
                    return 1
                fi
                ;;
            *)
                echo "Unsupported package manager. Please install LACT manually."
                return 1
                ;;
        esac
    else
        echo "LACT is already installed."
    fi

    echo "Enabling and starting LACT service..."
    if command_exists systemctl; then
        sudo systemctl enable --now lactd
    else
        echo "systemd not detected. Please start LACT service manually."
    fi

    echo "LACT has been installed and started successfully."
}

checkEnv
setupLACT
