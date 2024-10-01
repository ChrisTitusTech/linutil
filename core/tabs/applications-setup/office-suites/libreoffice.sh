#!/bin/sh -e

. ../common-script.sh

checkLibeOfficeInstallation() {
    case "$PACKAGER" in
        zypper|dnf)
            checkFlatpak
            flatpak_app_exists org.libreoffice.LibreOffice
            ;;
        *)
            command_exists meld
            ;;
    esac
}

installLibreOffice() {
    if ! checkLibeOfficeInstallation; then
        printf "%b\n" "${YELLOW}Installing Libre Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y libreoffice-core
                ;;
            zypper|dnf)
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