#!/bin/sh -e

. ../../common-script.sh

installNextcloud() {
    if ! command_exists com.nextcloud.desktopclient.nextcloud && ! command_exists nextcloud; then
        printf "%b\n" "${YELLOW}Installing Nextcloud...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y nextcloud-desktop
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y nextcloud-client
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm nextcloud-client
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y nextcloud-desktop
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add nextcloud-client
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub com.nextcloud.desktopclient.nextcloud
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Nextcloud is already installed.${RC}"
    fi
}

checkEnv
installNextcloud