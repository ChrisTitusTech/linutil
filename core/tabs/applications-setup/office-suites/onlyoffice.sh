#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.onlyoffice.desktopeditors"
APP_UNINSTALL_PKGS=""


installOnlyOffice() {
    if ! flatpak_app_installed org.onlyoffice.desktopeditors && ! command_exists onlyoffice-desktopeditors; then
        printf "%b\n" "${YELLOW}Installing Only Office..${RC}."
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
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}Unsupported package manager: ""$PACKAGER"". Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists onlyoffice-desktopeditors; then
            return 0
        fi
        if try_flatpak_install org.onlyoffice.desktopeditors; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Only Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installOnlyOffice
