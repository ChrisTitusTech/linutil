#!/bin/sh -e

. ../common-script.sh

installAlacritty() {
    if ! command_exists alacritty; then
    printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm alacritty
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
    if [ -d "${HOME}/.config/alacritty" ]; then
        if [ -d "${HOME}/.config/alacritty-linutilbak" ]; then
            rm -rf "${HOME}/.config/alacritty-linutilbak"
        fi
        mv "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-linutilbak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/keybinds.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/keybinds.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
    printf "%b\n" "${GREEN}Alacritty configuration files copied.${RC}"
}

checkEnv
checkEscalationTool
installAlacritty
setupAlacrittyConfig
