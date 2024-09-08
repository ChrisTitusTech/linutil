#!/bin/sh -e

# Import common utilities
. ./common-script.sh

# Function to prompt user for font selection
prompt_font_selection() {
    fonts=(
        "0xProto Nerd Font"
        "3270 Nerd Font"
        "Agave Nerd Font"
        "AnonymicePro Nerd Font"
        "Arimo Nerd Font"
        "AurulentSansMono Nerd Font"
        "BigBlueTerminal Nerd Font"
        "BitstromWera Nerd Font"
        "BlexMono Nerd Font"
        "CaskaydiaCove Nerd Font"
        "CaskaydiaMono Nerd Font"
        "CodeNewRoman Nerd Font"
        "ComicShannsMono Nerd Font"
        "CommitMono Nerd Font"
        "Cousine Nerd Font"
        "D2Coding Nerd Font"
        "DaddyTimeMono Nerd Font"
        "DejaVuSansMono Nerd Font"
        "DroidSansMono Nerd Font"
        "EnvyCodeR Nerd Font"
        "FantasqueSansMono Nerd Font"
        "FiraCode Nerd Font"
        "FiraMono Nerd Font"
        "GeistMono Nerd Font"
        "GoMono Nerd Font"
        "Gohu Nerd Font"
        "Hack Nerd Font"
        "Hasklug Nerd Font"
        "HeavyDataMono Nerd Font"
        "Hurmit Nerd Font"
        "iM-Writing Nerd Font"
        "Inconsolata Nerd Font"
        "InconsolataGo Nerd Font"
        "Inconsolata LGC Nerd Font"
        "IntoneMono Nerd Font"
        "Iosevka Nerd Font"
        "IosevkaTerm Nerd Font"
        "IosevkaTermSlab Nerd Font"
        "JetBrainsMono Nerd Font"
        "Lekton Nerd Font"
        "Literation Nerd Font"
        "Lilex Nerd Font"
        "MartianMono Nerd Font"
        "Meslo Nerd Font"
        "Monaspice Nerd Font"
        "Monofur Nerd Font"
        "Monoid Nerd Font"
        "Mononoki Nerd Font"
        "M+ Nerd Font"
        "Noto Nerd Font"
        "OpenDyslexic Nerd Font"
        "Overpass Nerd Font"
        "ProFont Nerd Font"
        "ProggyClean Nerd Font"
        "RecMono Nerd Font"
        "RobotoMono Nerd Font"
        "SauceCodePro Nerd Font"
        "ShureTechMono Nerd Font"
        "SpaceMono Nerd Font"
        "Terminess Nerd Font"
        "Tinos Nerd Font"
        "Ubuntu Nerd Font"
        "UbuntuMono Nerd Font"
        "VictorMono Nerd Font"
        "ZedMono Nerd Font"
    )

    echo "Select fonts to install (separate with spaces):"
    echo "---------------------------------------------"
    for i in "${!fonts[@]}"; do
        echo " $i  -  ${fonts[i]}"
    done
    echo "---------------------------------------------"

    read -rp "Enter the numbers of the fonts to install (e.g., '0 1 2'): " font_selection

    echo "Fonts selected: $font_selection"
}

# Function to download and install the selected fonts
download_and_install_fonts() {
    for selection in $font_selection; do
        font=${fonts[$selection]}
        font_name=$(echo "$font" | awk '{print $1}')
        echo "Downloading and installing $font..."
        
        # Check if wget and tar are installed, using common-script.sh helper
        checkCommandRequirements "wget"
        checkCommandRequirements "tar"

        # Download the font
        wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.tar.xz" -P "$HOME/tmp"
        
        # Extract and install the font
        mkdir -p ~/.local/share/fonts
        tar -xf "$HOME/tmp/$font_name.tar.xz" -C "$HOME/.local/share/fonts"
        rm "$HOME/tmp/$font_name.tar.xz"
    done

    # Update the font cache
    fc-cache -vf
    echo "Fonts installed and cache updated."
}

# Function to check environment and dependencies
check_environment() {
    echo "Checking environment..."
    checkEnv  # Assuming this is a function from common-script.sh
}

# Main script execution
check_environment
prompt_font_selection
download_and_install_fonts
