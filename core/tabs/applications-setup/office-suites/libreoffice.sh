#!/bin/sh -e

. ../../common-script.sh

installLibreOffice() {
    if ! command_exists org.libreoffice.LibreOffice && ! command_exists libreoffice; then
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
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak --noninteractive org.libreoffice.LibreOffice
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Libre Office is already installed.${RC}"
    fi
}

checkEnv
installLibreOffice