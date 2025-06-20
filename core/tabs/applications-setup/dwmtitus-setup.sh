#!/bin/sh

. ../common-script.sh
. ../common-service-script.sh

setupDWM() {
    printf "%b\n" "${YELLOW}Installing DWM-Titus...${RC}"
    case "$PACKAGER" in # Install pre-Requisites
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel libx11 libxinerama libxft imlib2 git unzip flameshot lxappearance feh mate-polkit
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add build-base libxinerama-dev libxft-dev imlib2-dev font-dejavu dbus-x11 git unzip flameshot feh polkit
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y build-essential libx11-dev libxinerama-dev libxft-dev libimlib2-dev libx11-xcb-dev libfontconfig1 libx11-6 libxft2 libxinerama1 libxcb-res0-dev git unzip flameshot lxappearance feh mate-polkit
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y "@development-tools" || "$ESCALATION_TOOL" "$PACKAGER" group install -y "Development Tools"
            "$ESCALATION_TOOL" "$PACKAGER" install -y libX11-devel libXinerama-devel libXft-devel imlib2-devel libxcb-devel unzip flameshot lxappearance feh mate-polkit # no need to include git here as it should be already installed via "Development Tools"
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER"  install -y make libX11-devel libXinerama-devel libXft-devel imlib2-devel gcc
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy base-devel freetype-devel fontconfig-devel imlib2-devel libXft-devel libXinerama-devel git unzip flameshot lxappearance feh mate-polkit
            ;; 
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y -c system.devel
            "$ESCALATION_TOOL" "$PACKAGER" install -y libxcb-devel libxinerama-devel libxft-devel imlib2-devel git unzip flameshot lxappearance feh mate-polkit xcb-util-devel
            ;;   
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

setupPicomDependencies() {
    printf "%b\n" "${YELLOW}Installing Picom dependencies if not already installed${RC}"
    
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm libxcb meson libev uthash libconfig
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add libxcb-dev meson libev-dev uthash-dev libconfig-dev pixman-dev xcb-util-image-dev xcb-util-renderutil-dev pcre2-dev libepoxy-dev dbus-dev xcb-util-dev
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libxcb1-dev libxcb-res0-dev libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-dpms0-dev libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev libxext-dev meson ninja-build uthash-dev
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libxcb-devel dbus-devel gcc git libconfig-devel libdrm-devel libev-devel libX11-devel libX11-xcb libXext-devel libxcb-devel libGL-devel libEGL-devel libepoxy-devel meson pcre2-devel pixman-devel uthash-devel xcb-util-image-devel xcb-util-renderutil-devel xorg-x11-proto-devel xcb-util-devel
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libxcb-devel libxcb-devel dbus-1-devel gcc git libconfig-devel libdrm-devel libev-devel libX11-devel libX11-xcb1 libXext-devel libxcb-devel Mesa-libGL-devel Mesa-libEGL-devel libepoxy-devel meson pcre2-devel uthash-devel xcb-util-image-devel libpixman-1-0-devel xcb-util-renderutil-devel xcb-util-devel
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy meson libev-devel uthash libconfig-devel pixman-devel xcb-util-image-devel xcb-util-renderutil-devel pcre2-devel libepoxy-devel dbus-devel
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libxcb-devel meson libev-devel uthash-devel libconfig-devel pixman-devel xcb-util-image-devel xcb-util-renderutil-devel pcre2-devel libepoxy-devel dbus-devel xcb-util-devel
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}Picom dependencies installed successfully${RC}"
}

makeDWM() {
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/dwm-titus.git # CD to Home directory to install dwm-titus
    # This path can be changed (e.g. to linux-toolbox directory)
    cd dwm-titus/ # Hardcoded path, maybe not the best.
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
    else
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
    fi
}

picom_animations() {
    # clone the repo into .local/share & use the -p flag to avoid overwriting that dir
    mkdir -p "$HOME/.local/share/"
    if [ ! -d "$HOME/.local/share/ftlabs-picom" ]; then
        if ! git clone https://github.com/FT-Labs/picom.git "$HOME/.local/share/ftlabs-picom"; then
            printf "%b\n" "${RED}Failed to clone the repository${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Repository already exists, skipping clone${RC}"
    fi

    cd "$HOME/.local/share/ftlabs-picom" || { printf "%b\n" "${RED}Failed to change directory to picom${RC}"; return 1; }

    # Build the project
    if ! meson setup --buildtype=release build; then
        printf "%b\n" "${RED}Meson setup failed${RC}"
        return 1
    fi

    if ! ninja -C build; then
        printf "%b\n" "${RED}Ninja build failed${RC}"
        return 1
    fi

    # Install the built binary
    if ! "$ESCALATION_TOOL" ninja -C build install; then
        printf "%b\n" "${RED}Failed to install the built binary${RC}"
        return 1
    fi

    printf "%b\n" "${GREEN}Picom animations installed successfully${RC}"
}

clone_config_folders() {
    # Ensure the target directory exists
    [ ! -d ~/.config ] && mkdir -p ~/.config

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
        if ! git clone https://github.com/ChrisTitusTech/nord-background.git "$PIC_DIR/nord-background"; then
            # If the git clone command fails, print an error message and return with a status of 1
            printf "%b\n" "${RED}Failed to clone the repository${RC}"
            return 1
        fi
        # Rename the cloned directory to 'backgrounds'
        mv "$PIC_DIR/nord-background" "$PIC_DIR/backgrounds"
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
        apk)
            "$ESCALATION_TOOL" setup-xorg-base
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xorg xinit
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xorg-x11-xinit xorg-x11-server-Xorg
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xinit xorg-x11-server
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy xorg-minimal
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xorg-server xinit
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
    printf "%b\n" "${GREEN}Current display manager: $currentdm${RC}"
    if [ "$currentdm" = "none" ]; then
        printf "%b\n" "${YELLOW}--------------------------${RC}" 
        printf "%b\n" "${YELLOW}Pick your Display Manager ${RC}" 
        printf "%b\n" "${YELLOW}1. SDDM ${RC}" 
        printf "%b\n" "${YELLOW}2. LightDM ${RC}" 
        printf "%b\n" "${YELLOW}3. GDM ${RC}" 
        printf "%b\n" "${YELLOW}4. None ${RC}" 
        printf "%b" "${YELLOW}Please select one: ${RC}"
        read -r choice
        case "$choice" in
            1)
                DM="sddm"
                ;;
            2)
                DM="lightdm"
                ;;
            3)
                DM="gdm"
                ;;
            4)
                printf "%b\n" "${GREEN}No display manager will be installed${RC}"
                return 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid selection! Please choose 1, 2, 3, or 4.${RC}"
                return 1
                ;;
        esac
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lightdm-gtk-greeter
                fi
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" add lightdm-gtk-greeter
                fi
                ;;    
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" -Sy lightdm-gtk-greeter
                fi
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
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

install_slstatus() {
    printf "Do you want to install slstatus? (y/N): "
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        printf "%b\n" "${YELLOW}Installing slstatus${RC}"
        cd "$HOME/dwm-titus/slstatus" || { 
            printf "%b\n" "${RED}Failed to change directory to slstatus${RC}"
            return 1
        }
        if "$ESCALATION_TOOL" make clean install; then
            printf "%b\n" "${GREEN}slstatus installed successfully${RC}"
        else
            printf "%b\n" "${RED}Failed to install slstatus${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Skipping slstatus installation${RC}"
    fi
    cd "$HOME"
}

checkEnv
checkEscalationTool
setupDisplayManager
setupDWM
setupPicomDependencies
makeDWM
install_slstatus
install_nerd_font
picom_animations
clone_config_folders
configure_backgrounds
