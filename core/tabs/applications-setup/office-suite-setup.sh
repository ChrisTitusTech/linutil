#!/bin/sh -e

. ../common-script.sh

install_onlyoffice() {
    if ! command_exists onlyoffice-desktopeditors; then
        printf "%b\n" "${YELLOW}Installing Only Office..${RC}."
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./onlyoffice-desktopeditors_amd64.deb
                ;;
            zypper|dnf)
                . ./setup-flatpak.sh
                flatpak install -y flathub org.onlyoffice.desktopeditors
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

install_libreoffice() {
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

install_wpsoffice() {
    if ! command_exists com.wps.Office; then
        printf "%b\n" "${YELLOW}Installing WPS Office...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --noconfirm wps-office
                ;;
            *)
                . ./setup-flatpak.sh
                flatpak install flathub com.wps.Office
                ;;
        esac
    else
        printf "%b\n" "${GREEN}WPS Office is already installed.${RC}"
    fi
}

# needs to be updated every year for latest version
install_freeoffice() {  
    if ! command_exists softmaker-freeoffice-2024 freeoffice softmaker; then
        printf "%b\n" "${YELLOW}Installing Free Office...${RC}"
        case "$PACKAGER" in
        apt-get|nala)
            curl -O https://www.softmaker.net/down/softmaker-freeoffice-2024_1218-01_amd64.deb
            "$ESCALATION_TOOL" "$PACKAGER" install -y ./softmaker-freeoffice-2024_1218-01_amd64.deb
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" addrepo -f https://shop.softmaker.com/repo/rpm SoftMaker
            "$ESCALATION_TOOL" "$PACKAGER" --gpg-auto-import-keys refresh
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install softmaker-freeoffice-2024
            ;;
        pacman)
            "$AUR_HELPER" -S --noconfirm freeoffice
            ;;
        dnf)
            "$ESCALATION_TOOL" curl -O -qO /etc/yum.repos.d/softmaker.repo https://shop.softmaker.com/repo/softmaker.repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y softmaker-freeoffice-2024
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Free Office is already installed.${RC}"
    fi
}

install_evince() {
    if ! command_exists evince; then
        printf "%b\n" "${YELLOW}Installing Evince...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm evince
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y evince
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Evince is already installed.${RC}"
    fi
}

install_okular() {
    if ! command_exists okular; then
        printf "%b\n" "${YELLOW}Installing Okular...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm okular
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y okular
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Okular is already installed.${RC}"
    fi
}

install_pdfstudioviewer() {
    if ! command_exists pdfstudioviewer2024/pdfstudioviewer2024; then
        printf "%b\n" "${YELLOW}Installing PDF Studio Viewer...${RC}"
        curl -O https://download.qoppa.com/pdfstudioviewer/PDFStudioViewer_linux64.sh
        "$ESCALATION_TOOL" chmod +x PDFStudioViewer_linux64.sh
        if sh PDFStudioViewer_linux64.sh; then
            printf "%b\n" "${GREEN}PDF Studio Viewer installed successfully!${RC}"
        else
            printf "%b\n" "${RED}Installation failed!${RC}"
        fi
        rm PDFStudioViewer_linux64.sh
    else
        printf "%b\n" "${GREEN}PDF Studio Viewer is already installed.${RC}"
    fi
}

install_pdfstudio() {
    if ! command_exists pdfstudio2024/pdfstudio2024; then
        printf "%b\n" "${YELLOW}Installing PDF Studio...${RC}"
        curl -O https://download.qoppa.com/pdfstudio/PDFStudio_linux64.sh
        "$ESCALATION_TOOL" chmod +x PDFStudio_linux64.sh
        if sh PDFStudio_linux64.sh; then
            printf "%b\n" "${GREEN}PDF Studio installed successfully!${RC}"
        else
            printf "%b\n" "${RED}PDF Studio installation failed!${RC}"
        fi
        rm PDFStudio_linux64.sh
    else
        printf "%b\n" "${GREEN}PDF Studio is already installed.${RC}"
    fi
}

officeSuiteSetup() {
    clear
    printf "%b\n" "Office Suite Setup Script"
    printf "%b\n" "----------------------------"
    printf "%b\n" "Select the suite you want to install:"
    printf "%b\n" "1. OnlyOffice"
    printf "%b\n" "2. LibreOffice"
    printf "%b\n" "3. WPS Office"
    printf "%b\n" "4. Free Office"
    printf "%b\n" "Select the PDF Suite you want to install:"
    printf "%b\n" "----------------------------"
    printf "%b\n" "5. Evince"
    printf "%b\n" "6. Okular"
    printf "%b\n" "7. PDF Studio Viewer"
    printf "%b\n" "8. PDF Studio (Paid Software)"
    printf "%b\n" "----------------------------"
    printf "%b"  "Enter your choices (e.g., 1 3 5): "
    read -r choice
    for ch in $choice; do
        case $ch in
                1) install_onlyoffice ;;
                2) install_libreoffice ;;
                3) install_wpsoffice ;;
                4) install_freeoffice ;;
                5) install_evince ;;
                6) install_okular ;;
                7) install_pdfstudioviewer ;;
                8) install_pdfstudio ;;
                *) printf "%b\n" "${RED}Invalid option: $ch ${RC}" ;;
            esac
        done
    printf "%b\n" "${GREEN}Installation complete!${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
officeSuiteSetup