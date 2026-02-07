#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.libreoffice.LibreOffice"
APP_UNINSTALL_PKGS="libreoffice libreoffice-core"


installLibreOffice() {
    if ! flatpak_app_installed org.libreoffice.LibreOffice && ! command_exists libreoffice; then
        printf "%b\n" "${YELLOW}Installing Libre Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y libreoffice-core
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm libreoffice-fresh
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add libreoffice
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy libreoffice
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" -y install libreoffice
                ;;
            zypper|dnf)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}Unsupported package manager: ""$PACKAGER"". Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists libreoffice; then
            return 0
        fi
        if try_flatpak_install org.libreoffice.LibreOffice; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Libre Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installLibreOffice
