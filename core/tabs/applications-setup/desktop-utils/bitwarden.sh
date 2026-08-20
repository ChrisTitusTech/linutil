#!/bin/sh -e

. ../../common-script.sh

installBitwarden() {
    if ! command_exists com.bitwarden.desktop && ! command_exists bitwarden-desktop; then
        printf "%b\n" "${YELLOW}Installing Bitwarden...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                # Ensure the downloaded .deb is removed even on failure under `set -e`.
                trap 'rm -f bitwarden.deb' EXIT
                curl -fLo bitwarden.deb "https://bitwarden.com/download/?app=desktop&platform=linux&variant=deb"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./bitwarden.deb
                rm -f bitwarden.deb
                trap - EXIT
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "https://bitwarden.com/download/?app=desktop&platform=linux&variant=rpm"
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm bitwarden
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub com.bitwarden.desktop
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Bitwarden is already installed.${RC}"
    fi
}

checkEnv
installBitwarden