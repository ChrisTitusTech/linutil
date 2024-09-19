#!/bin/sh -e

. ../common-script.sh

installKitty() {
    printf "%b" "${YELLOW}Do you want to install Kitty? (Y/n): ${RC}"
    read -r install_choice
    if [ "$install_choice" != "n" ] && [ "$install_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Installing Kitty...${RC}"
        if ! command_exists kitty; then
            case "$PACKAGER" in
                pacman)
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm kitty
                    ;;
                *)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y kitty
                    ;;
            esac
        else
            printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Skipping Kitty installation.${RC}"
    fi
}

setupKittyConfig() {
    printf "%b" "${YELLOW}Do you want to backup existing Kitty configuration files? (Y/n): ${RC}"
    read -r backup_choice
    if [ "$backup_choice" != "n" ] && [ "$backup_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Backing up existing Kitty configuration files...${RC}"
        if [ -d "${HOME}/.config/kitty" ] && [ ! -d "${HOME}/.config/kitty-bak" ]; then
            cp -r "${HOME}/.config/kitty" "${HOME}/.config/kitty-bak"
        fi
        printf "%b\n" "${GREEN}Kitty configuration files backed up.${RC}"
    else
        printf "%b\n" "${GREEN}Skipping backup of Kitty configuration files.${RC}"
    fi
    mkdir -p "${HOME}/.config/kitty/"
    curl -sSLo "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    curl -sSLo "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
checkEscalationTool
installKitty
setupKittyConfig