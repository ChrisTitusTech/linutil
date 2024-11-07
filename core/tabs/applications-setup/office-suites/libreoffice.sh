#!/bin/sh -e

. ../../common-script.sh

installLibreOffice() {
    if ! command_exists org.libreoffice.LibreOffice && ! command_exists libreoffice; then
        printf "%b\n" "${YELLOW}Installing Libre Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y libreoffice-core
                ;;
            zypper|dnf)
                checkFlatpak
                flatpak install -y flathub org.libreoffice.LibreOffice
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm libreoffice-fresh
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add libreoffice
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