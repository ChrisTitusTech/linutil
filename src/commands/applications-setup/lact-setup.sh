#!/bin/sh -e

. ../common-script.sh

setuplact() {
    echo "Installing Lact"
    if command_exists lact; then
        echo "Lact already Installed"
    fi    
        case $PACKAGER in
        pacman)   
            $AUR_HELPER -S --noconfirm lact
            $ESCALATION_TOOL systemctl enable --now lactd
            ;;
        dnf)
            VERSION=$(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | grep -Po '"tag_name": "\K[^"]*')
            RPM_FILE="lact-${VERSION}-0.x86_64.fedora-40.rpm"
            curl -L -o "$RPM_FILE" "https://github.com/ilya-zlobintsev/LACT/releases/latest/download/$RPM_FILE"
            $ESCALATION_TOOL $PACKAGER install -y "$RPM_FILE"
            $ESCALATION_TOOL systemctl enable --now lactd
            rm "$RPM_FILE"
            ;;
        zypper)
            VERSION=$(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | grep -Po '"tag_name": "\K[^"]*')
            RPM_FILE="lact-${VERSION}-0.x86_64.opensuse-tumbleweed.rpm"
            curl -L -o "$RPM_FILE" "https://github.com/ilya-zlobintsev/LACT/releases/latest/download/$RPM_FILE"
            $ESCALATION_TOOL $PACKAGER in -y "$RPM_FILE"
            $ESCALATION_TOOL systemctl enable --now lactd
            rm "$RPM_FILE"
            ;;
        apt-get)
            VERSION=$(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | grep -Po '"tag_name": "\K[^"]*')
            DEB_FILE="lact_${VERSION}_amd64.deb"
            curl -L -o "$DEB_FILE" "https://github.com/ilya-zlobintsev/LACT/releases/latest/download/$DEB_FILE"
            $ESCALATION_TOOL $PACKAGER install -y "$DEB_FILE"
            $ESCALATION_TOOL systemctl enable --now lactd
            rm "$DEB_FILE"
            ;;
        *)
            echo "Unsupported package manager: $PACKAGER"
            exit 1
            ;;
        esac
}

checkEnv
checkAURHelper
checkEscalationTool
setuplact
