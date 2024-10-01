#!/bin/sh -e

. ../../common-script.sh

installLibreOffice() {
    if ! command_exists libreoffice; then
        printf "%b\n" "${YELLOW}Installing Libre Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y libreoffice-core
                ;;
            zypper|dnf)
                . ./setup-flatpak.sh
                flatpak install -y flathub org.libreoffice.LibreOffice
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm libreoffice-fresh
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