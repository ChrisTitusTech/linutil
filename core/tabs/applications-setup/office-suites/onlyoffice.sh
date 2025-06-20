#!/bin/sh -e

. ../../common-script.sh

installOnlyOffice() {
    if ! command_exists org.onlyoffice.desktopeditors && ! command_exists onlyoffice-desktopeditors; then
        printf "%b\n" "${YELLOW}Installing Only Office..${RC}."
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./onlyoffice-desktopeditors_amd64.deb
                ;;
            zypper|dnf|xbps-install|eopkg|apk)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install -y flathub org.onlyoffice.desktopeditors
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm onlyoffice
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Only Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installOnlyOffice