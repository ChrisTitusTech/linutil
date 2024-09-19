#!/bin/sh -e

. ../common-script.sh

installAlacritty() {
    printf "%b" "${YELLOW}Do you want to install Alacritty? (Y/n): ${RC}"
    read -r install_choice
    if [ "$install_choice" != "n" ] && [ "$install_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
        if ! command_exists alacritty; then
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
    else
        printf "%b\n" "${GREEN}Skipping Alacritty installation.${RC}"
    fi
}

setupAlacrittyConfig() {
    printf "%b" "${YELLOW}Do you want to backup existing configuration files? (Y/n): ${RC}"
    read -r backup_choice
    if [ "$backup_choice" != "n" ] && [ "$backup_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Backing up existing Alacritty config files...${RC}"
        if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
            cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
        fi
        printf "%b\n" "${GREEN}Alacritty configuration files backed up.${RC}"
    else
        printf "%b\n" "${GREEN}Skipping backup of Alacritty configuration files.${RC}"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/keybinds.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/keybinds.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
}

checkEnv
checkEscalationTool
installAlacritty
setupAlacrittyConfig