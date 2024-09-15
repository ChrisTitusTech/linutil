#!/bin/sh -e

. ../common-script.sh

setupRofi() {
    echo "Install Rofi if not already installed..."
    if ! command_exists rofi; then
        case "$PACKAGER" in
            pacman)
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm rofi
                ;;
            *)
                $ESCALATION_TOOL "$PACKAGER" install -y rofi
                ;;
        esac
    else
        echo "Rofi is already installed."
    fi
    echo "Copy Rofi config files"
    if [ -d "$HOME/.config/rofi" ]; then
        cp -r "$HOME/.config/rofi" "$HOME/.config/rofi-bak"
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

revertRofi() {
    echo "Reverting Rofi configuration..."
    CONFIG_DIR="$HOME/.config/rofi"

    if [ -d "${CONFIG_DIR}" ]; then
        rm -rf "$CONFIG_DIR"
        mv "${HOME}/.config/rofi-bak" "${HOME}/.config/rofi"
        echo "Rofi configuration reverted."

        if command_exists rofi; then
            printf "Do you want to uninstall Rofi as well? (y/N): "
            read uninstall_choice
            if [ "$uninstall_choice" = "y" ] || [ "$uninstall_choice" = "Y" ]; then
                case ${PACKAGER} in
                    pacman)
                        $ESCALATION_TOOL ${PACKAGER} -Rns --noconfirm rofi
                        ;;
                    *)
                        $ESCALATION_TOOL ${PACKAGER} remove -y rofi
                        ;;
                esac
                echo "Rofi uninstalled."
            fi
        fi
    else
        echo "No Rofi configuration found. Nothing to revert."
    fi
}

run() {
    checkEnv
    checkEscalationTool
    setupRofi
}

revert() {
    checkEnv
    checkEscalationTool
    revertRofi
}