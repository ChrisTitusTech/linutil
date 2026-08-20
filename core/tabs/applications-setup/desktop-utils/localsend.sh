#!/bin/sh -e

. ../../common-script.sh

installLocalsend() {
    if ! command_exists org.localsend.localsend_app && ! command_exists localsend; then
        printf "%b\n" "${YELLOW}Installing Localsend...${RC}"
        case "$PACKAGER" in
            # I wanted to add APT release, but for some reason dev decided to put latest release with only Android releases, so won't rely on that
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm localsend-bin
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub org.localsend.localsend_app
                ;;
        esac
    else
        printf "%b\n" "${GREEN}LocalSend is already installed.${RC}"
    fi
}

checkEnv
installLocalsend