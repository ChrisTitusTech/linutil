#!/bin/sh -e

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo -e "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo -e "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

cd "$LINUXTOOLBOXDIR" || exit

install_theme_tools() {
    echo -e "${YELLOW}Installing theme tools (qt6ct and kvantum)...${RC}"
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
            echo -e "${RED}Unsupported package manager. Please install qt6ct and kvantum manually.${RC}"
            exit 1
            ;;
    esac
}

configure_qt6ct() {
    echo -e "${YELLOW}Configuring qt6ct...${RC}"
    mkdir -p "$HOME/.config/qt6ct"
    cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
style=kvantum
color_scheme=default
icon_theme=breeze
EOF
    echo -e "${GREEN}qt6ct configured successfully.${RC}"
}

configure_kvantum() {
    echo -e "${YELLOW}Configuring Kvantum...${RC}"
    mkdir -p "$HOME/.config/Kvantum"
    cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=Breeze
EOF
    echo -e "${GREEN}Kvantum configured successfully.${RC}"
}

checkEnv
install_theme_tools
configure_qt6ct
configure_kvantum