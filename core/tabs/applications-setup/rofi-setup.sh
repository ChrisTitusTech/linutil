#!/bin/sh -e

. ../common-script.sh

installRofi() {
    if ! command_exists rofi; then
    printf "%b\n" "${YELLOW}Installing Rofi...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm rofi
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add rofi
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y rofi
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Rofi is already installed.${RC}"
    fi
}

setupRofiConfig() {
    printf "%b\n" "${YELLOW}Copying Rofi configuration files...${RC}"
    if [ -d "$HOME/.config/rofi" ] && [ ! -d "$HOME/.config/rofi-bak" ]; then
        cp -r "$HOME/.config/rofi" "$HOME/.config/rofi-bak"
    fi
    mkdir -p "$HOME/.config/rofi"
    curl -sSLo "$HOME/.config/rofi/powermenu.sh" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/powermenu.sh
    chmod +x "$HOME/.config/rofi/powermenu.sh"
    curl -sSLo "$HOME/.config/rofi/config.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/config.rasi
    mkdir -p "$HOME/.config/rofi/themes"
    curl -sSLo "$HOME/.config/rofi/themes/nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/nord.rasi
    curl -sSLo "$HOME/.config/rofi/themes/sidetab-nord.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/sidetab-nord.rasi
    curl -sSLo "$HOME/.config/rofi/themes/powermenu.rasi" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/rofi/themes/powermenu.rasi
}

checkEnv
checkEscalationTool
installRofi
setupRofiConfig
