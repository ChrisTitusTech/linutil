#!/bin/sh -e

. ../../common-script.sh

installZenBrowser() {
    if ! command_exists io.github.zen_browser.zen && ! command_exists zen-browser; then
        printf "%b\n" "${YELLOW}Installing Zen Browser...${RC}"
        case "$PACKAGER" in
        pacman)
            if grep -q avx2 /proc/cpuinfo; then
                "$AUR_HELPER" -S --needed --noconfirm zen-browser-avx2-bin
            else
                "$AUR_HELPER" -S --needed --noconfirm zen-browser-bin
            fi
            ;;
        *)
            checkFlatpak
            flatpak install -y flathub io.github.zen_browser.zen
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Zen Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installZenBrowser
