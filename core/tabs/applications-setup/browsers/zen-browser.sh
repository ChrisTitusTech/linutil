#!/bin/sh -e

. ../../common-script.sh

installZenBrowser() {
    if ! flatpak_app_installed io.github.zen_browser.zen && ! command_exists zen-browser; then
        printf "%b\n" "${YELLOW}Installing Zen Browser...${RC}"
        if try_flatpak_install io.github.zen_browser.zen; then
            return 0
        fi
        case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm zen-browser-bin
            ;;
        *)
            printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
            exit 1
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
