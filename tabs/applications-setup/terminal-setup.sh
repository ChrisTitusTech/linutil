#!/bin/sh -e

. ../common-script.sh

chooseTerminal() {
    echo "Choose your preferred terminal:"
    echo "1) Alacritty"
    echo "2) Kitty"
    echo "Enter your choice (1-2): "
    read -r choice

    case $choice in
        1)
            installAlacritty
            setupAlacrittyConfig
            ;;
        2)
            installKitty
            setupKittyConfig
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Please choose one of the options available.${RC}"
            exit 1
            ;;
    esac
}

installAlacritty() {
    printf "%b\n" "${YELLOW}Installing Alacritty...${RC}"
    if ! command_exists alacritty; then
        case "$PACKAGER" in
            pacman)
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm alacritty
                ;;
            *)
                $ESCALATION_TOOL "$PACKAGER" install -y alacritty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Alacritty is already installed.${RC}"
    fi
}

setupAlacrittyConfig() {
    printf "%b\n" "${YELLOW}Copy alacritty config files${RC}"
    if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
    printf "%b\n" "${GREEN}Alacritty configuration files copied.${RC}"
}

installKitty() {
    printf "%b\n" "${YELLOW}Install Kitty if not already installed...${RC}"
    if ! command_exists kitty; then
        case "$PACKAGER" in
            pacman)
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm kitty
                ;;
            *)
                $ESCALATION_TOOL "$PACKAGER" install -y kitty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Kitty is already installed.${RC}"
    fi
}

setupKittyConfig() {
    printf "%b\n" "${YELLOW}Copying Kitty configuration files...${RC}"
    if [ -d "${HOME}/.config/kitty" ] && [ ! -d "${HOME}/.config/kitty-bak" ]; then
        cp -r "${HOME}/.config/kitty" "${HOME}/.config/kitty-bak"
    fi
    mkdir -p "${HOME}/.config/kitty/"
    curl -sSLo "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    curl -sSLo "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

checkEnv
checkEscalationTool
chooseTerminal