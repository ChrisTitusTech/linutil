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
    if [ -d "${HOME}/.config/qt6ct" ] && [ ! -d "${HOME}/.config/qt6ct-bak" ]; then
        cp -r "${HOME}/.config/qt6ct" "${HOME}/.config/qt6ct-bak"
    fi
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
    if [ -d "${HOME}/.config/Kvantum" ] && [ ! -d "${HOME}/.config/Kvantum-bak" ]; then
        cp -r "${HOME}/.config/Kvantum" "${HOME}/.config/Kvantum-bak"
    fi
    mkdir -p "$HOME/.config/Kvantum"
    cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=Breeze
EOF
    printf "${GREEN}Kvantum configured successfully.${RC}\n"
}

revertGlobalTheme() {
    echo "Reverting global theme setup..."
    
    if [ -d "$HOME/.config/qt6ct-bak" ]; then
        rm -rf "$HOME/.config/qt6ct"
        mv "$HOME/.config/qt6ct-bak" "$HOME/.config/qt6ct"
        echo "qt6ct configuration reverted."
    else
        echo "No qt6ct configuration found. Nothing to revert."
    fi

    if [ -d "$HOME/.config/Kvantum-bak" ]; then
        rm -rf "$HOME/.config/Kvantum"
        mv "$HOME/.config/Kvantum-bak" "$HOME/.config/Kvantum"
        echo "Kvantum configuration reverted."
    else
        echo "No Kvantum configuration found. Nothing to revert."
    fi

    if command_exists qt6ct || command_exists kvantum; then
        printf "Do you want to uninstall the theme tools as well? (y/N): "
        read uninstall_choice
        if [ "$uninstall_choice" = "y" ] || [ "$uninstall_choice" = "Y" ]; then
            case $PACKAGER in
                pacman)
                    $ESCALATION_TOOL ${PACKAGER} -Rns --noconfirm qt6ct kvantum
                    ;;
                *)
                    $ESCALATION_TOOL ${PACKAGER} remove -y qt6ct kvantum
                    ;;
            esac
            echo "Theme tools uninstalled."
        fi
    fi
}

run() {
    checkEnv
    checkEscalationTool
    install_theme_tools
    configure_qt6ct
    configure_kvantum
}

revert() {
    checkEnv
    checkEscalationTool
    revertGlobalTheme
}