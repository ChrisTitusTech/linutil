#!/bin/sh

# Import common utilities
. ./common-script.sh

# List of available fonts
fonts="
0xProto_Nerd_Font
3270_Nerd_Font
Agave_Nerd_Font
AnonymicePro_Nerd_Font
Arimo_Nerd_Font
AurulentSansMono_Nerd_Font
BigBlueTerminal_Nerd_Font
BitstromWera_Nerd_Font
BlexMono_Nerd_Font
CaskaydiaCove_Nerd_Font
CaskaydiaMono_Nerd_Font
CodeNewRoman_Nerd_Font
ComicShannsMono_Nerd_Font
CommitMono_Nerd_Font
Cousine_Nerd_Font
D2Coding_Nerd_Font
DaddyTimeMono_Nerd_Font
DejaVuSansMono_Nerd_Font
DroidSansMono_Nerd_Font
EnvyCodeR_Nerd_Font
FantasqueSansMono_Nerd_Font
FiraCode_Nerd_Font
FiraMono_Nerd_Font
GeistMono_Nerd_Font
GoMono_Nerd_Font
Gohu_Nerd_Font
Hack_Nerd_Font
Hasklug_Nerd_Font
HeavyDataMono_Nerd_Font
Hurmit_Nerd_Font
iM-Writing_Nerd_Font
Inconsolata_Nerd_Font
InconsolataGo_Nerd_Font
Inconsolata_LGC_Nerd_Font
IntoneMono_Nerd_Font
Iosevka_Nerd_Font
IosevkaTerm_Nerd_Font
IosevkaTermSlab_Nerd_Font
JetBrainsMono_Nerd_Font
Lekton_Nerd_Font
Literation_Nerd_Font
Lilex_Nerd_Font
MartianMono_Nerd_Font
Meslo_Nerd_Font
Monaspice_Nerd_Font
Monofur_Nerd_Font
Monoid_Nerd_Font
Mononoki_Nerd_Font
M+_Nerd_Font
Noto_Nerd_Font
OpenDyslexic_Nerd_Font
Overpass_Nerd_Font
ProFont_Nerd_Font
ProggyClean_Nerd_Font
RecMono_Nerd_Font
RobotoMono_Nerd_Font
SauceCodePro_Nerd_Font
ShureTechMono_Nerd_Font
SpaceMono_Nerd_Font
Terminess_Nerd_Font
Tinos_Nerd_Font
Ubuntu_Nerd_Font
UbuntuMono_Nerd_Font
VictorMono_Nerd_Font
ZedMono_Nerd_Font
"

# Function to prompt user for font selection
prompt_font_selection() {
    echo "Select fonts to install (separate with spaces):"
    echo "---------------------------------------------"
    i=0
    for font in $fonts; do
        echo " $i  -  $font"
        i=$((i + 1))
    done
    echo "---------------------------------------------"

    printf "Enter the numbers of the fonts to install (e.g., '0 1 2'): "
    read font_selection

    echo "Fonts selected: $font_selection"
}

# Function to download and install the selected fonts
download_and_install_fonts() {
    i=0
    for font in $fonts; do
        for selection in $font_selection; do
            if [ "$i" = "$selection" ]; then
                font_name=$(echo "$font" | sed 's/_/ /g')  # Replace underscores with spaces
                echo "Downloading and installing $font_name..."
                
                # Check if wget and tar are installed, using common-script.sh helper
                checkCommandRequirements "wget"
                checkCommandRequirements "tar"

                # Download the font
                wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.tar.xz" -P "$HOME/tmp"
                
                # Extract and install the font
                mkdir -p ~/.local/share/fonts
                tar -xf "$HOME/tmp/$font_name.tar.xz" -C "$HOME/.local/share/fonts"
                rm "$HOME/tmp/$font_name.tar.xz"
            fi
        done
        i=$((i + 1))
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
