#!/bin/sh -e

. ../../common-script.sh

installVsCode() {
    if ! command_exists com.visualstudio.code && ! command_exists code; then
        printf "%b\n" "${YELLOW}Installing VS Code..${RC}."
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                "$ESCALATION_TOOL" install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
                echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/vscode.list > /dev/null
                rm -f packages.microsoft.gpg
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y apt-transport-https code
                ;;
            zypper)
                "$ESCALATION_TOOL" rpm --import https://packages.microsoft.com/keys/microsoft.asc
                printf "%b\n" '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' | "$ESCALATION_TOOL" tee /etc/zypp/repos.d/vscode.repo > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install code
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm visual-studio-code-bin
                ;;
            dnf)
                "$ESCALATION_TOOL" rpm --import https://packages.microsoft.com/keys/microsoft.asc
                printf "%b\n" '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' | "$ESCALATION_TOOL" tee /etc/yum.repos.d/vscode.repo > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" install -y code
                ;;
            apk)
                checkFlatpak
                flatpak install -y flathub com.visualstudio.code
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}VS Code is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installVsCode 
