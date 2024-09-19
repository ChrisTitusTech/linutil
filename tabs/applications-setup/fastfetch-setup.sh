#!/bin/sh -e

. ../common-script.sh

installFastfetch() {
    printf "%b" "${YELLOW}Do you want to install Fastfetch? (Y/n): ${RC}"
    read -r install_choice
    if [ "$install_choice" != "n" ] && [ "$install_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${RC}"
        if ! command_exists fastfetch; then
            case "$PACKAGER" in
                pacman)
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fastfetch
                    ;;
                *)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
                    ;;
            esac
        else
            printf "%b\n" "${GREEN}Fastfetch is already installed.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Skipping Fastfetch installation.${RC}"
    fi
}

setupFastfetchConfig() {
    printf "%b" "${YELLOW}Do you want to backup existing Fastfetch configuration files? (Y/n): ${RC}"
    read -r backup_choice
    if [ "$backup_choice" != "n" ] && [ "$backup_choice" != "N" ]; then
        printf "%b\n" "${YELLOW}Backing up existing Fastfetch configuration files...${RC}"
        if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
            cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
        fi
        printf "%b\n" "${GREEN}Fastfetch configuration files backed up.${RC}"
    else
        printf "%b\n" "${GREEN}Skipping backup of Fastfetch configuration files.${RC}"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
}

checkEnv
checkEscalationTool
installFastfetch
setupFastfetchConfig