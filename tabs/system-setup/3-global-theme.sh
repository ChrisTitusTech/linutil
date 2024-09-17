#!/bin/sh -e

. ../common-script.sh

install_theme_tools() {
    printf "%b\n" "${YELLOW}Installing theme tools (qt6ct and kvantum)...${RC}\n"
    case $PACKAGER in
        apt|nala)
            $ESCALATION_TOOL "${PACKAGER}" update
            $ESCALATION_TOOL "${PACKAGER}" install -y qt6ct kvantum
            ;;
        zypper)
            $ESCALATION_TOOL "${PACKAGER}" refresh
            $ESCALATION_TOOL "${PACKAGER}" --non-interactive install qt6ct kvantum
            ;;
        dnf)
            $ESCALATION_TOOL "${PACKAGER}" update
            $ESCALATION_TOOL "${PACKAGER}" install -y qt6ct kvantum
            ;;
        pacman)
            $ESCALATION_TOOL "${PACKAGER}" -S --needed --noconfirm qt6ct kvantum
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager. Please install qt6ct and kvantum manually.${RC}\n"
            exit 1
            ;;
    esac
}

configure_qt6ct() {
    printf "%b\n" "${YELLOW}Configuring qt6ct...${RC}\n"
    mkdir -p "$HOME/.config/qt6ct"
    cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
style=kvantum
color_scheme=default
icon_theme=breeze
EOF
    printf "%b\n" "${GREEN}qt6ct configured successfully.${RC}\n"

    # Add QT_QPA_PLATFORMTHEME to /etc/environment
    if ! grep -q "QT_QPA_PLATFORMTHEME=qt6ct" /etc/environment; then
        printf "%b\n" "${YELLOW}Adding QT_QPA_PLATFORMTHEME to /etc/environment...${RC}\n"
        echo "QT_QPA_PLATFORMTHEME=qt6ct" | $ESCALATION_TOOL tee -a /etc/environment > /dev/null
        printf "%b\n" "${GREEN}QT_QPA_PLATFORMTHEME added to /etc/environment.${RC}\n"
    else
        printf "%b\n" "${GREEN}QT_QPA_PLATFORMTHEME already set in /etc/environment.${RC}\n"
    fi
}

configure_kvantum() {
    printf "%b\n" "${YELLOW}Configuring Kvantum...${RC}\n"
    mkdir -p "$HOME/.config/Kvantum"
    cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=Breeze
EOF
    printf "%b\n" "${GREEN}Kvantum configured successfully.${RC}\n"
}

checkEnv
checkEscalationTool
install_theme_tools
configure_qt6ct
configure_kvantum
