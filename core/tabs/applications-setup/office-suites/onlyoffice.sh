#!/bin/sh -e

. ../../common-script.sh

installOnlyOffice() {
    if ! flatpak_app_installed org.onlyoffice.desktopeditors && ! command_exists onlyoffice-desktopeditors; then
        printf "%b\n" "${YELLOW}Installing Only Office..${RC}."
        if try_flatpak_install org.onlyoffice.desktopeditors; then
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./onlyoffice-desktopeditors_amd64.deb
                "$ESCALATION_TOOL" rm ./onlyoffice-desktopeditors_amd64.deb
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm onlyoffice
                ;;
            zypper|dnf|xbps-install|eopkg|apk)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
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
