#!/bin/sh -e

. ../common-script.sh

makeDWM() {
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/dwm-titus.git # CD to Home directory to install dwm-titus
    # This path can be changed (e.g. to linux-toolbox directory)
    cd dwm-titus/ # Hardcoded path, maybe not the best.
    $ESCALATION_TOOL make clean install # Run make clean install
}

setupDWM() {
    echo "Installing DWM-Titus if not already installed"
    case "$PACKAGER" in # Install pre-Requisites
        pacman)
            $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm base-devel libx11 libxinerama libxft imlib2 libxcb
            ;;
        apt|nala)
            $ESCALATION_TOOL "$PACKAGER" install -y build-essential libx11-dev libxinerama-dev libxft-dev libimlib2-dev libx11-xcb-dev libfontconfig1 libx11-6 libxft2 libxinerama1 libxcb-res0-dev
            ;;
        dnf)
            $ESCALATION_TOOL "$PACKAGER" groupinstall -y "Development Tools"
            $ESCALATION_TOOL "$PACKAGER" install -y libX11-devel libXinerama-devel libXft-devel imlib2-devel libxcb-devel
            ;;
        *)
            echo "Unsupported package manager: $PACKAGER"
            exit 1
            ;;
    esac
}

install_nerd_font() {
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_ZIP="$FONT_DIR/Meslo.zip"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_INSTALLED=$(fc-list | grep -i "Meslo")

    # Check if Meslo Nerd-font is already installed
    if [ -n "$FONT_INSTALLED" ]; then
        echo "Meslo Nerd-fonts are already installed."
        return 0
    fi

    echo "Installing Meslo Nerd-fonts"

    # Create the fonts directory if it doesn't exist
    if [ ! -d "$FONT_DIR" ]; then
        mkdir -p "$FONT_DIR" || {
            echo "Failed to create directory: $FONT_DIR"
            return 1
        }
    else
        echo "$FONT_DIR exists, skipping creation."
    fi

    # Check if the font zip file already exists
    if [ ! -f "$FONT_ZIP" ]; then
        # Download the font zip file
        curl -sSLo "$FONT_ZIP" "$FONT_URL" || {
            echo "Failed to download Meslo Nerd-fonts from $FONT_URL"
            return 1
        }
    else
        echo "Meslo.zip already exists in $FONT_DIR, skipping download."
    fi

    # Unzip the font file if it hasn't been unzipped yet
    if [ ! -d "$FONT_DIR/Meslo" ]; then
        unzip "$FONT_ZIP" -d "$FONT_DIR" || {
            echo "Failed to unzip $FONT_ZIP"
            return 1
        }
    else
        echo "Meslo font files already unzipped in $FONT_DIR, skipping unzip."
    fi

    # Remove the zip file
    rm "$FONT_ZIP" || {
        echo "Failed to remove $FONT_ZIP"
        return 1
    }

    # Rebuild the font cache
    fc-cache -fv || {
        echo "Failed to rebuild font cache"
        return 1
    }

    echo "Meslo Nerd-fonts installed successfully"
}

picom_animations() {
    # Clone the repository in the home/build directory
    mkdir -p ~/build
    if [ ! -d ~/build/picom ]; then
        if ! git clone https://github.com/FT-Labs/picom.git ~/build/picom; then
            echo "Failed to clone the repository"
            return 1
        fi
    else
        echo "Repository already exists, skipping clone"
    fi

    cd ~/build/picom || { echo "Failed to change directory to picom"; return 1; }

    # Build the project
    if ! meson setup --buildtype=release build; then
        echo "Meson setup failed"
        return 1
    fi

    if ! ninja -C build; then
        echo "Ninja build failed"
        return 1
    fi

    # Install the built binary
    if ! $ESCALATION_TOOL ninja -C build install; then
        echo "Failed to install the built binary"
        return 1
    fi

    echo "Picom animations installed successfully"
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
            echo "Cloned $dir_name to ~/.config/"
        else
            echo "Directory $dir_name does not exist, skipping"
        fi
    done
}

configure_backgrounds() {
    # Set the variable BG_DIR to the path where backgrounds will be stored
    BG_DIR="$HOME/Pictures/backgrounds"

    # Check if the ~/Pictures directory exists
    if [ ! -d "~/Pictures" ]; then
        # If it doesn't exist, print an error message and return with a status of 1 (indicating failure)
        echo "Pictures directory does not exist"
        mkdir ~/Pictures
        echo "Directory was created in Home folder"
    fi
    
    # Check if the backgrounds directory (BG_DIR) exists
    if [ ! -d "$BG_DIR" ]; then
        # If the backgrounds directory doesn't exist, attempt to clone a repository containing backgrounds
        if ! git clone https://github.com/ChrisTitusTech/nord-background.git ~/Pictures; then
            # If the git clone command fails, print an error message and return with a status of 1
            echo "Failed to clone the repository"
            return 1
        fi
        # Rename the cloned directory to 'backgrounds'
        mv ~/Pictures/nord-background ~/Pictures/backgrounds
        # Print a success message indicating that the backgrounds have been downloaded
        echo "Downloaded desktop backgrounds to $BG_DIR"    
    else
        # If the backgrounds directory already exists, print a message indicating that the download is being skipped
        echo "Path $BG_DIR exists for desktop backgrounds, skipping download of backgrounds"
    fi
}

setupDisplayManager() {
    echo "Setting up Xorg"
    case "$PACKAGER" in
        pacman)
            $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm xorg-xinit xorg-server
            ;;
        apt|nala)
            $ESCALATION_TOOL "$PACKAGER" install -y xorg xinit
            ;;
        dnf)
            $ESCALATION_TOOL "$PACKAGER" install -y xorg-x11-xinit xorg-x11-server-Xorg
            ;;
        *)
            echo "Unsupported package manager: $PACKAGER"
            exit 1
            ;;
    esac
    echo "Xorg installed successfully"
    echo "Setting up Display Manager"
    currentdm="none"
    for dm in gdm sddm lightdm; do
        if systemctl is-active --quiet "$dm.service"; then
            currentdm="$dm"
            break
        fi
    done
    echo "Current display manager: $currentdm"
    if [ "$currentdm" = "none" ]; then
        DM="sddm"
        echo "No display manager found, installing $DM"
        case "$PACKAGER" in
            pacman)
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm "$DM"
                ;;
            apt|nala)
                $ESCALATION_TOOL "$PACKAGER" install -y "$DM"
                ;;
            dnf)
                $ESCALATION_TOOL "$PACKAGER" install -y "$DM"
                ;;
            *)
                echo "Unsupported package manager: $PACKAGER"
                exit 1
                ;;
        esac
        echo "$DM installed successfully"
        systemctl enable "$DM"

        # Prompt user for auto-login
        # Using printf instead of echo -n as It's more posix-compliant.
        printf "Do you want to enable auto-login? (Y/n) "
        read -r answer
        case "$answer" in
            [Yy]*)
                echo "Configuring SDDM for autologin"
                SDDM_CONF="/etc/sddm.conf"
                if [ ! -f "$SDDM_CONF" ]; then
                    echo "[Autologin]" | $ESCALATION_TOOL tee -a "$SDDM_CONF"
                    echo "User=$USER" | $ESCALATION_TOOL tee -a "$SDDM_CONF"
                    echo "Session=dwm" | $ESCALATION_TOOL tee -a "$SDDM_CONF"
                else
                    $ESCALATION_TOOL sed -i '/^\[Autologin\]/d' "$SDDM_CONF"
                    $ESCALATION_TOOL sed -i '/^User=/d' "$SDDM_CONF"
                    $ESCALATION_TOOL sed -i '/^Session=/d' "$SDDM_CONF"
                    echo "[Autologin]" | $ESCALATION_TOOL tee -a "$SDDM_CONF"
                    echo "User=$USER" | $ESCALATION_TOOL tee -a "$SDDM_CONF"
                    echo "Session=dwm" | $ESCALATION_TOOL tee -a "$SDDM_CONF"
                fi
                echo "Checking if autologin group exists"
                if ! getent group autologin > /dev/null; then
                    echo "Creating autologin group"
                    $ESCALATION_TOOL groupadd autologin
                else
                    echo "Autologin group already exists"
                fi
                echo "Adding user with UID 1000 to autologin group"
                USER_UID_1000=$(getent passwd 1000 | cut -d: -f1)
                if [ -n "$USER_UID_1000" ]; then
                    $ESCALATION_TOOL usermod -aG autologin "$USER_UID_1000"
                    echo "User $USER_UID_1000 added to autologin group"
                else
                    echo "No user with UID 1000 found - Auto login not possible"
                fi
                ;;
            *)
                echo "Auto-login configuration skipped"
                ;;
        esac
    fi
    

    
}

install_slstatus() {
    printf "Do you want to install slstatus? (y/N): " # using printf instead of 'echo' to avoid newline, -n flag for 'echo' is not supported in POSIX
    read -r response # -r flag to prevent backslashes from being interpreted
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        echo "Installing slstatus"
        cd "$HOME/dwm-titus/slstatus" || { echo "Failed to change directory to slstatus"; return 1; }
        if $ESCALATION_TOOL make clean install; then
            echo "slstatus installed successfully"
        else
            echo "Failed to install slstatus"
            return 1
        fi
    else
        echo "Skipping slstatus installation"
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
