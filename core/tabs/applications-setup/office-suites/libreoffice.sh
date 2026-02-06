#!/bin/sh -e

. ../../common-script.sh

installLibreOffice() {
    if ! flatpak_app_installed org.libreoffice.LibreOffice && ! command_exists libreoffice; then
        printf "%b\n" "${YELLOW}Installing Libre Office...${RC}"
        if try_flatpak_install org.libreoffice.LibreOffice; then
            return 0
        fi
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
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Libre Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installLibreOffice
