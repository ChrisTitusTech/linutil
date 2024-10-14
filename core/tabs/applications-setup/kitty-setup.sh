#!/bin/sh -e

. ../common-script.sh

installKitty() {
    if ! command_exists kitty; then
        printf "%b\n" "${YELLOW}Installing Kitty...${RC}"
        case "$PACKAGER" in
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm kitty
                ;;
            *)
                elevated_execution "$PACKAGER" install -y kitty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
    fi
}

setupKittyConfig() {
    printf "%b\n" "${YELLOW}Copying Kitty configuration files...${RC}"
    if [ -d "${HOME}/.config/kitty" ] && [ ! -d "${HOME}/.config/kitty-bak" ]; then
        cp -r "${HOME}/.config/kitty" "${HOME}/.config/kitty-bak"
    fi
    mkdir -p "${HOME}/.config/kitty/"
    curl -sSLo "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    curl -sSLo "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
checkEscalationTool
installKitty
setupKittyConfig