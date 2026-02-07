#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="io.github.zen_browser.zen"
APP_UNINSTALL_PKGS=""


installZenBrowser() {
    if ! flatpak_app_installed io.github.zen_browser.zen && ! command_exists zen-browser; then
        printf "%b\n" "${YELLOW}Installing Zen Browser...${RC}"
        case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm zen-browser-bin
            ;;
        *)
            printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
            ;;
        esac
        if command_exists zen-browser; then
            return 0
        fi
        if try_flatpak_install io.github.zen_browser.zen; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Zen Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installZenBrowser
