#!/bin/sh -e

. ./common-script.sh

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    printf "${YELLOW}Creating linuxtoolbox directory: %s${RC}\n" "$LINUXTOOLBOXDIR"
    mkdir -p "$LINUXTOOLBOXDIR"
    printf "${GREEN}linuxtoolbox directory created: %s${RC}\n" "$LINUXTOOLBOXDIR"
fi

cd "$LINUXTOOLBOXDIR" || exit

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
        echo "QT_QPA_PLATFORMTHEME=qt6ct" | sudo tee -a /etc/environment > /dev/null
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
install_theme_tools
configure_qt6ct
configure_kvantum
