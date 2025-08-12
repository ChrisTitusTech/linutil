#!/bin/sh -e

. ../common-script.sh

installAlacritty() {
    if ! command_exists alacritty; then
    printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm alacritty
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add alacritty
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy alacritty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y alacritty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Alacritty is already installed.${RC}"
    fi
}

setupAlacrittyConfig() {
    printf "%b\n" "${YELLOW}Copying alacritty config files...${RC}"
    if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/keybinds.toml" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/alacritty/keybinds.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/alacritty/nordic.toml"
    printf "%b\n" "${GREEN}Alacritty configuration files copied.${RC}"
}

checkEnv
checkEscalationTool
installAlacritty
setupAlacrittyConfig
