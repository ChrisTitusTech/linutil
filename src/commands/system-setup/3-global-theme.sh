#!/bin/sh -e

. ./common-script.sh

install_theme_tools() {
    printf "${YELLOW}Installing theme tools (qt6ct and kvantum)...${RC}\n"
    case $PACKAGER in
        apt-get)
            sudo apt-get update
            sudo apt-get install -y qt6ct kvantum
            ;;
        zypper)
            sudo zypper refresh
            sudo zypper --non-interactive install qt6ct kvantum
            ;;
        dnf)
            sudo dnf update
            sudo dnf install -y qt6ct kvantum
            ;;
        pacman)
            sudo pacman -Sy
            sudo pacman --noconfirm -S qt6ct kvantum
            ;;
        *)
            printf "${RED}Unsupported package manager. Please install qt6ct and kvantum manually.${RC}\n"
            exit 1
            ;;
    esac
}
common_qt(){
    # Add QT_QPA_PLATFORMTHEME to /etc/environment
if ! grep -q "QT_QPA_PLATFORMTHEME=qt6ct" /etc/environment; then
    printf "${YELLOW}Adding QT_QPA_PLATFORMTHEME to /etc/environment...${RC}\n"
    echo "QT_QPA_PLATFORMTHEME=qt6ct" | sudo tee -a /etc/environment > /dev/null
    printf "${GREEN}QT_QPA_PLATFORMTHEME added to /etc/environment.${RC}\n"
else
    printf "${GREEN}QT_QPA_PLATFORMTHEME already set in /etc/environment.${RC}\n"
fi

}


checkEnv
install_theme_tools
common_qt
