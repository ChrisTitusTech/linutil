#!/bin/sh -e

. ../common-script.sh

setupDWM() {
    printf "%b\n" "${YELLOW}Installing DWM-Titus if not already installed${RC}"
    case "$PACKAGER" in # Install pre-Requisites
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel libx11 libxinerama libxft imlib2 libxcb git
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y build-essential libx11-dev libxinerama-dev libxft-dev libimlib2-dev libx11-xcb-dev libfontconfig1 libx11-6 libxft2 libxinerama1 libxcb-res0-dev git
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" groupinstall -y "Development Tools"
            "$ESCALATION_TOOL" "$PACKAGER" install -y libX11-devel libXinerama-devel libXft-devel imlib2-devel libxcb-devel
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
}

makeDWM() {
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/dwm-titus.git # CD to Home directory to install dwm-titus
    # This path can be changed (e.g. to linux-toolbox directory)
    cd dwm-titus/ # Hardcoded path, maybe not the best.
    "$ESCALATION_TOOL" make clean install # Run make clean install
}

install_nerd_font() {
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_ZIP="$FONT_DIR/Meslo.zip"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_INSTALLED=$(fc-list | grep -i "Meslo")

    # Check if Meslo Nerd-font is already installed
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
        printf "%b\n" "${GREEN}$FONT_DIR exists, skipping creation.${RC}"
    fi

    # Check if the font zip file already exists
    if [ ! -f "$FONT_ZIP" ]; then
        # Download the font zip file
        curl -sSLo "$FONT_ZIP" "$FONT_URL" || {
            printf "%b\n" "${RED}Failed to download Meslo Nerd-fonts from $FONT_URL${RC}"
            return 1
        }
    else
        printf "%b\n" "${GREEN}Meslo.zip already exists in $FONT_DIR, skipping download.${RC}"
    fi

    # Unzip the font file if it hasn't been unzipped yet
    if [ ! -d "$FONT_DIR/Meslo" ]; then
        unzip "$FONT_ZIP" -d "$FONT_DIR" || {
            printf "%b\n" "${RED}Failed to unzip $FONT_ZIP${RC}"
            return 1
        }
    else
        printf "%b\n" "${GREEN}Meslo font files already unzipped in $FONT_DIR, skipping unzip.${RC}"
    fi

    # Remove the zip file
    rm "$FONT_ZIP" || {
        printf "%b\n" "${RED}Failed to remove $FONT_ZIP${RC}"
        return 1
    }

    # Rebuild the font cache
    fc-cache -fv || {
        printf "%b\n" "${RED}Failed to rebuild font cache${RC}"
        return 1
    }

    printf "%b\n" "${GREEN}Meslo Nerd-fonts installed successfully${RC}"
}

picom_animations() {
    # Clone the repository in the home/build directory
    mkdir -p ~/build
    if [ ! -d ~/build/picom ]; then
        if ! git clone https://github.com/FT-Labs/picom.git ~/build/picom; then
            printf "%b\n" "${RED}Failed to clone the repository${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Repository already exists, skipping clone${RC}"
    fi

    cd ~/build/picom || { printf "%b\n" "${RED}Failed to change directory to picom${RC}"; return 1; }

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
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xorg xinit
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xorg-x11-xinit xorg-x11-server-Xorg
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
        if systemctl is-active --quiet "$dm.service"; then
            currentdm="$dm"
            break
        fi
    done
    printf "%b\n" "${GREEN}Current display manager: $currentdm${RC}"
    if [ "$currentdm" = "none" ]; then
        DM="sddm"
        printf "%b\n" "${YELLOW}No display manager found, installing $DM${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$DM"
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
                exit 1
                ;;
        esac
        printf "%b\n" "${GREEN}$DM installed successfully${RC}"
        systemctl enable "$DM"

        # Prompt user for auto-login
        # Using printf instead of echo -n as It's more posix-compliant.
        printf "Do you want to enable auto-login? (Y/n) "
        read -r answer
        case "$answer" in
            [Yy]*)
                printf "%b\n" "${YELLOW}Configuring SDDM for autologin${RC}"
                SDDM_CONF="/etc/sddm.conf"
                if [ ! -f "$SDDM_CONF" ]; then
                    echo "[Autologin]" | "$ESCALATION_TOOL" tee -a "$SDDM_CONF"
                    echo "User=$USER" | "$ESCALATION_TOOL" tee -a "$SDDM_CONF"
                    echo "Session=dwm" | "$ESCALATION_TOOL" tee -a "$SDDM_CONF"
                else
                    "$ESCALATION_TOOL" sed -i '/^\[Autologin\]/d' "$SDDM_CONF"
                    "$ESCALATION_TOOL" sed -i '/^User=/d' "$SDDM_CONF"
                    "$ESCALATION_TOOL" sed -i '/^Session=/d' "$SDDM_CONF"
                    echo "[Autologin]" | "$ESCALATION_TOOL" tee -a "$SDDM_CONF"
                    echo "User=$USER" | "$ESCALATION_TOOL" tee -a "$SDDM_CONF"
                    echo "Session=dwm" | "$ESCALATION_TOOL" tee -a "$SDDM_CONF"
                fi
                printf "%b\n" "{YELLOW}Checking if autologin group exists${RC}"
                if ! getent group autologin > /dev/null; then
                    printf "%b\n" "${YELLOW}Creating autologin group${RC}"
                    "$ESCALATION_TOOL" groupadd autologin
                else
                    printf "%b\n" "${GREEN}Autologin group already exists${RC}"
                fi
                printf "%b\n" "${YELLOW}Adding user with UID 1000 to autologin group${RC}"
                USER_UID_1000=$(getent passwd 1000 | cut -d: -f1)
                if [ -n "$USER_UID_1000" ]; then
                    "$ESCALATION_TOOL" usermod -aG autologin "$USER_UID_1000"
                    printf "%b\n" "${GREEN}User $USER_UID_1000 added to autologin group${RC}"
                else
                    printf "%b\n" "${RED}No user with UID 1000 found - Auto login not possible${RC}"
                fi
                ;;
            *)
                printf "%b\n" "${GREEN}Auto-login configuration skipped${RC}"
                ;;
        esac
    fi
}

install_slstatus() {
    printf "Do you want to install slstatus? (y/N): " # using printf instead of 'echo' to avoid newline, -n flag for 'echo' is not supported in POSIX
    read -r response # -r flag to prevent backslashes from being interpreted
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        printf "%b\n" "${YELLOW}Installing slstatus${RC}"
        cd "$HOME/dwm-titus/slstatus" || { echo "Failed to change directory to slstatus"; return 1; }
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
makeDWM
install_slstatus
install_nerd_font
clone_config_folders
configure_backgrounds