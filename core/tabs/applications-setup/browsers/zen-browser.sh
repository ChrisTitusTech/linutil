#!/bin/sh -e

. ../../common-script.sh

installZenBrowser() {
    if ! command_exists io.github.zen_browser.zen && ! command_exists zen-browser; then
        printf "%b\n" "${YELLOW}Installing Zen Browser...${RC}"
        case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm zen-browser-bin
            ;;
        *)
            checkFlatpak
            "$ESCALATION_TOOL" flatpak install --noninteractive flathub io.github.zen_browser.zen
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Zen Browser is already installed.${RC}"
    fi
}

checkEnv
installZenBrowser
