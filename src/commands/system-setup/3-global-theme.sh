#!/bin/sh -e

. ../common-script.sh

install_theme_tools() {
    printf "${YELLOW}Installing theme tools (qt6ct and kvantum)...${RC}\n"
    case $PACKAGER in
        apt-get)
            $ESCALATION_TOOL apt-get update
            $ESCALATION_TOOL apt-get install -y qt6ct kvantum
            ;;
        zypper)
            $ESCALATION_TOOL zypper refresh
            $ESCALATION_TOOL zypper --non-interactive install qt6ct kvantum
            ;;
        dnf)
            $ESCALATION_TOOL dnf update
            $ESCALATION_TOOL dnf install -y qt6ct kvantum
            ;;
        pacman)
            $ESCALATION_TOOL pacman -S --needed --noconfirm qt6ct kvantum
            ;;
        *)
            printf "${RED}Unsupported package manager. Please install qt6ct and kvantum manually.${RC}\n"
            exit 1
            ;;
    esac
}

configure_qt6ct() {
    printf "${YELLOW}Configuring qt6ct...${RC}\n"
    mkdir -p "$HOME/.config/qt6ct"
    cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
style=kvantum
color_scheme=default
icon_theme=breeze
EOF
    printf "${GREEN}qt6ct configured successfully.${RC}\n"

    # Add QT_QPA_PLATFORMTHEME to /etc/environment
    if ! grep -q "QT_QPA_PLATFORMTHEME=qt6ct" /etc/environment; then
        printf "${YELLOW}Adding QT_QPA_PLATFORMTHEME to /etc/environment...${RC}\n"
        echo "QT_QPA_PLATFORMTHEME=qt6ct" | $ESCALATION_TOOL tee -a /etc/environment > /dev/null
        printf "${GREEN}QT_QPA_PLATFORMTHEME added to /etc/environment.${RC}\n"
    else
        printf "${GREEN}QT_QPA_PLATFORMTHEME already set in /etc/environment.${RC}\n"
    fi
}

configure_kvantum() {
    printf "${YELLOW}Configuring Kvantum...${RC}\n"
    mkdir -p "$HOME/.config/Kvantum"
    cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=Breeze
EOF
    printf "${GREEN}Kvantum configured successfully.${RC}\n"
}

checkEnv
checkEscalationTool
install_theme_tools
configure_qt6ct
configure_kvantum
