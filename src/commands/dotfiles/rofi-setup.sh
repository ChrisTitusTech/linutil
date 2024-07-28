#!/bin/sh -e

. ./common-script.sh

setupRofi() {
    echo "Install Rofi if not already installed..."
    if ! command_exists rofi; then
        case "$PACKAGER" in
            pacman)
                sudo "$PACKAGER" -S --noconfirm rofi
                ;;
            *)
                sudo "$PACKAGER" install -y rofi
                ;;
        esac
    else
        echo "Rofi is already installed."
    fi
    echo "Copy Rofi config files"
    if [ -d "$HOME/.config/rofi" ]; then
        cp -r "$HOME/.config/rofi" "$HOME/.config/rofi.bak"
    fi
    mkdir -p "$HOME/.config/rofi"
    wget -O "$HOME/.config/rofi/powermenu.sh" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/powermenu.sh
    chmod +x "$HOME/.config/rofi/powermenu.sh"
    wget -O "$HOME/.config/rofi/config.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/config.rasi
    mkdir -p "$HOME/.config/rofi/themes"
    wget -O "$HOME/.config/rofi/themes/nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/nord.rasi
    wget -O "$HOME/.config/rofi/themes/sidetab-nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/sidetab-nord.rasi
    wget -O "$HOME/.config/rofi/themes/powermenu.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/powermenu.rasi
}

checkEnv
setupRofi
