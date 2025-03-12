#!/bin/sh -e

. ../common-script.sh

install_theme_tools() {
    printf "%b\n" "${YELLOW}Installing theme tools (qt6ct and kvantum)...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qt6ct kvantum
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install qt6ct kvantum
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qt6ct kvantum
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qt6ct kvantum
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy qt6ct kvantum
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

applyTheming() {
    printf "%b\n" "${YELLOW}Applying global theming...${RC}"
    case "$XDG_CURRENT_DESKTOP" in
        KDE)
            lookandfeeltool -a org.kde.breezedark.desktop
            successOutput
            exit 0
            ;;
        GNOME)
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
            successOutput
            exit 0
            ;;
        *)
            return
            ;;
    esac
}

configure_qt6ct() {
    printf "%b\n" "${YELLOW}Configuring qt6ct...${RC}"
    mkdir -p "$HOME/.config/qt6ct"
    cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
style=kvantum
color_scheme=default
icon_theme=breeze
EOF
    printf "%b\n" "${GREEN}qt6ct configured successfully.${RC}"

    # Add QT_QPA_PLATFORMTHEME to /etc/environment
    if ! grep -q "QT_QPA_PLATFORMTHEME=qt6ct" /etc/environment; then
        printf "%b\n" "${YELLOW}Adding QT_QPA_PLATFORMTHEME to /etc/environment...${RC}"
        echo "QT_QPA_PLATFORMTHEME=qt6ct" | "$ESCALATION_TOOL" tee -a /etc/environment > /dev/null
        printf "%b\n" "${GREEN}QT_QPA_PLATFORMTHEME added to /etc/environment.${RC}"
    else
        printf "%b\n" "${GREEN}QT_QPA_PLATFORMTHEME already set in /etc/environment.${RC}"
    fi
}

configure_kvantum() {
    printf "%b\n" "${YELLOW}Configuring Kvantum...${RC}"
    mkdir -p "$HOME/.config/Kvantum"
    cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=KvArcDark
EOF
    printf "%b\n" "${GREEN}Kvantum configured successfully.${RC}"
}

successOutput() {
    printf "%b\n" "${GREEN}Global theming applied successfully.${RC}"
}

checkEnv
checkEscalationTool
applyTheming
install_theme_tools
configure_qt6ct
configure_kvantum
successOutput