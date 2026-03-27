#!/bin/sh

. ../common-script.sh
. ../common-service-script.sh

setupDWM() {
    printf "%b\n" "${YELLOW}Installing DWM-Titus...${RC}"
    case "$PACKAGER" in # Install pre-Requisites
        pacman)
            NM_PACKAGE="networkmanager"
            if pacman -Qq networkmanager-iwd >/dev/null 2>&1; then
                NM_PACKAGE="networkmanager-iwd"
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel libx11 libxinerama libxft imlib2 libxcb git unzip flameshot nwg-look feh mate-polkit alsa-utils ghostty rofi xclip xarchiver thunar tumbler tldr gvfs thunar-archive-plugin dunst dex xscreensaver xorg-xprop xorg-xrandr xorg-xsetroot xorg-xset polybar picom xdg-user-dirs xdg-desktop-portal-gtk pipewire pavucontrol gnome-keyring flatpak "$NM_PACKAGE" network-manager-applet noto-fonts-emoji
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

makeDWM() {
    [ ! -d "$HOME/.local/share" ] && mkdir -p "$HOME/.local/share/"
    if [ ! -d "$HOME/.local/share/dwm-titus" ]; then
	printf "%b\n" "${YELLOW}DWM-Titus not found, cloning repository...${RC}"
	cd "$HOME/.local/share/" && git clone https://github.com/ChrisTitusTech/dwm-titus.git # CD to Home directory to install dwm-titus This path can be changed (e.g. to linux-toolbox directory)
	cd dwm-titus/ # Hardcoded path, maybe not the best.
    else
	printf "%b\n" "${GREEN}DWM-Titus directory already exists, replacing..${RC}"
	cd "$HOME/.local/share/dwm-titus" && git pull
    fi
    "$ESCALATION_TOOL" make clean install # Run make clean install
}

install_nerd_font() {
    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="MesloLGS Nerd Font Mono"
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_INSTALLED=$(fc-list | grep -i "Meslo")

    if [ -n "$FONT_INSTALLED" ]; then
        printf "%b\n" "${GREEN}Meslo Nerd-fonts are already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Meslo Nerd-fonts${RC}"

    # Create the fonts directory if it doesn't exist
    if [ ! -d "$FONT_DIR" ]; then
        mkdir -p "$FONT_DIR" || {
            printf "%b\n" "${RED}Failed to create directory: $FONT_DIR${RC}"
            return 1
        }
    fi
        printf "%b\n" "${YELLOW}Installing font '$FONT_NAME'${RC}"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
        unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR"/"$FONT_NAME"
        mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
        fc-cache -fv
        rm -rf "${TEMP_DIR}"
        printf "%b\n" "${GREEN}'$FONT_NAME' installed successfully.${RC}"
}

clone_config_folders() {
    # Ensure the target directory exists
    [ ! -d ~/.config ] && mkdir -p ~/.config
    [ ! -d ~/.local/bin ] && mkdir -p ~/.local/bin
    # Copy scripts to local bin
    cp -rf "$HOME/.local/share/dwm-titus/scripts/." "$HOME/.local/bin/"

    # Install Polybar icon fonts (MaterialIcons, Feather)
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    if [ -d "$HOME/.local/share/dwm-titus/polybar/fonts" ]; then
        cp -r "$HOME/.local/share/dwm-titus/polybar/fonts/"* "$FONT_DIR/"
        fc-cache -fv
        printf "%b\n" "${GREEN}Polybar icon fonts installed${RC}"
    fi

    # Iterate over all directories in config/*
    for dir in config/*/; do
        # Extract the directory name
        dir_name=$(basename "$dir")

        # Clone the directory to ~/.config/
        if [ -d "$dir" ]; then
            cp -r "$dir" ~/.config/
            printf "%b\n" "${GREEN}Cloned $dir_name to ~/.config/${RC}"
        else
            printf "%b\n" "${RED}Directory $dir_name does not exist, skipping${RC}"
        fi
    done
}

configure_backgrounds() {
    # Set the variable PIC_DIR which stores the path for images
    PIC_DIR="$HOME/Pictures"

    # Set the variable BG_DIR to the path where backgrounds will be stored
    BG_DIR="$PIC_DIR/backgrounds"

    # Check if the ~/Pictures directory exists
    if [ ! -d "$PIC_DIR" ]; then
        # If it doesn't exist, print an error message and return with a status of 1 (indicating failure)
        printf "%b\n" "${RED}Pictures directory does not exist${RC}"
        mkdir ~/Pictures
        printf "%b\n" "${GREEN}Directory was created in Home folder${RC}"
    fi

    # Check if the backgrounds directory (BG_DIR) exists
    if [ ! -d "$BG_DIR" ]; then
        # If the backgrounds directory doesn't exist, attempt to clone a repository containing backgrounds
        if ! git clone https://github.com/ChrisTitusTech/nord-background.git "$PIC_DIR/backgrounds"; then
            # If the git clone command fails, print an error message and return with a status of 1
            printf "%b\n" "${RED}Failed to clone the repository${RC}"
            return 1
        fi
        # Print a success message indicating that the backgrounds have been downloaded
        printf "%b\n" "${GREEN}Downloaded desktop backgrounds to $BG_DIR${RC}"    
    else
        # If the backgrounds directory already exists, print a message indicating that the download is being skipped
        printf "%b\n" "${GREEN}Path $BG_DIR exists for desktop backgrounds, skipping download of backgrounds${RC}"
    fi
}

setupDisplayManager() {
    printf "%b\n" "${YELLOW}Setting up Xorg${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm xorg-xinit xorg-server
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    printf "%b\n" "${GREEN}Xorg installed successfully${RC}"
    printf "%b\n" "${YELLOW}Setting up Display Manager${RC}"
    currentdm="none"
    for dm in gdm sddm lightdm; do
        if command -v "$dm" >/dev/null 2>&1 || isServiceActive "$dm"; then
            currentdm="$dm"
            break
        fi
    done
    printf "%b\n" "${GREEN}Display Manager Setup: $currentdm${RC}"
    if [ "$currentdm" = "none" ]; then
        printf "%b\n" "${YELLOW}--------------------------${RC}" 
        DM="sddm"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lightdm-gtk-greeter
                elif [ "$DM" = "sddm" ]; then
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
                fi
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
                exit 1
                ;;
        esac
        printf "%b\n" "${GREEN}$DM installed successfully${RC}"
        enableService "$DM"
        
	    fi
}

post_install_fixups() {
    printf "%b\n" "${YELLOW}Ensuring DWM session entry exists...${RC}"
    "$ESCALATION_TOOL" mkdir -p /usr/share/xsessions
    "$ESCALATION_TOOL" cp "$HOME/.local/share/dwm-titus/dwm.desktop" /usr/share/xsessions/
    "$ESCALATION_TOOL" chmod 644 /usr/share/xsessions/dwm.desktop

    found_sddm_autologin=0
    for autologin_file in /etc/sddm.conf.d/autologin.conf /etc/sddm.conf.d/autologin.conf.disabled /etc/sddm.conf.d/*autologin*.conf /etc/sddm.conf.d/*autologin*.disabled; do
        [ -e "$autologin_file" ] || continue
        if [ "$found_sddm_autologin" -eq 0 ]; then
            printf "%b\n" "${YELLOW}Found SDDM autologin config, disabling it...${RC}"
            "$ESCALATION_TOOL" mkdir -p /etc/sddm-disabled
            found_sddm_autologin=1
        fi
        "$ESCALATION_TOOL" mv "$autologin_file" /etc/sddm-disabled/
    done

    if [ "$found_sddm_autologin" -eq 1 ]; then
        printf "%b\n" "${GREEN}Moved SDDM autologin config(s) to /etc/sddm-disabled.${RC}"
    fi

    OWNER_USER="${SUDO_USER:-$USER}"
    OWNER_GROUP=$(id -gn "$OWNER_USER")
    if [ -d "$HOME/.config/dwm-titus" ]; then
        "$ESCALATION_TOOL" chown -R "$OWNER_USER:$OWNER_GROUP" "$HOME/.config/dwm-titus"
    fi
}

prompt_reboot() {
    while :; do
        printf "%b\n" "${YELLOW}Reboot now? (Recommended)${RC}"
        printf "%b" "Choices: Y / N: "
        read -r reboot_choice
        case "$reboot_choice" in
            Y|y)
                "$ESCALATION_TOOL" reboot
                return 0
                ;;
            N|n)
                printf "%b\n" "${GREEN}Returning to Linutil...${RC}"
                return 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid choice. Enter Y or N.${RC}"
                ;;
        esac
    done
}

uninstallDWM() {
    printf "%b\n" "${YELLOW}Uninstalling DWM-Titus...${RC}"
    REPO_DIR="$HOME/.local/share/dwm-titus"
    SCRIPT_NAMES=""
    CONFIG_DIR_NAMES=""

    if [ -d "$REPO_DIR/scripts" ]; then
        for f in "$REPO_DIR"/scripts/*; do
            [ -f "$f" ] || continue
            case "$(basename "$f")" in
                autostart*) continue ;;
            esac
            SCRIPT_NAMES="$SCRIPT_NAMES $(basename "$f")"
        done
    fi

    if [ -d "$REPO_DIR/config" ]; then
        for dir in "$REPO_DIR"/config/*/; do
            [ -d "$dir" ] || continue
            CONFIG_DIR_NAMES="$CONFIG_DIR_NAMES $(basename "$dir")"
        done
    fi

    if [ -d "$REPO_DIR" ]; then
        (
            cd "$REPO_DIR" || exit 1
            "$ESCALATION_TOOL" make uninstall || true
        )
    fi

    for script_name in $SCRIPT_NAMES; do
        "$ESCALATION_TOOL" rm -f "/usr/local/bin/$script_name" || true
        rm -f "$HOME/.local/bin/$script_name" || true
    done

    for config_name in $CONFIG_DIR_NAMES; do
        rm -rf "$HOME/.config/$config_name" || true
    done

    rm -rf "$HOME/.config/dwm-titus" || true
    "$ESCALATION_TOOL" rm -f /usr/share/xsessions/dwm.desktop || true
    rm -rf "$REPO_DIR" || true

    printf "%b\n" "${GREEN}DWM-Titus uninstall completed.${RC}"
}

installDWM() {
    setupDisplayManager
    setupDWM
    makeDWM
    install_nerd_font
    clone_config_folders
    configure_backgrounds
    post_install_fixups
    prompt_reboot
}

main() {
    printf "%b\n" "${YELLOW}DWM-Titus${RC}"
    printf "%b\n" "1. Install"
    printf "%b\n" "2. Uninstall"
    printf "%b\n" "3. Quit"
    printf "%b" "Select an option (1-3): "
    read -r choice

    case "$choice" in
        1) installDWM ;;
        2) uninstallDWM ;;
        3) exit 0 ;;
        *) printf "%b\n" "${RED}Invalid selection${RC}" ;;
    esac
}

checkEnv
main
