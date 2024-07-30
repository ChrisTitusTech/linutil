#!/bin/sh -e

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo -e "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo -e "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

if [ ! -d "$LINUXTOOLBOXDIR/linutil" ]; then
    echo -e "${YELLOW}Cloning linutil repository into: $LINUXTOOLBOXDIR/linutil${RC}"
    git clone https://github.com/ChrisTitusTech/linutil "$LINUXTOOLBOXDIR/linutil"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully cloned linutil repository${RC}"
    else
        echo -e "${RED}Failed to clone linutil repository${RC}"
        exit 1
    fi
fi

cd "$LINUXTOOLBOXDIR/linutil" || exit

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    case $PACKAGER in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | sudo tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
                sudo "$PACKAGER" -Sy
            else
                echo "Multilib is already enabled."
            fi
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                sudo "$PACKAGER" --noconfirm -S base-devel
                cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R "$USER":"$USER" ./yay-git
                cd yay-git && makepkg --noconfirm -si
            else
                echo "Aur helper already installed"
            fi
            if command_exists yay; then
                AUR_HELPER="yay"
            elif command_exists paru; then
                AUR_HELPER="paru"
            else
                echo "No AUR helper found. Please install yay or paru."
                exit 1
            fi
            "$AUR_HELPER" --noconfirm -S "$DEPENDENCIES"
            ;;
        apt-get|nala)
            COMPILEDEPS='build-essential'
            sudo "$PACKAGER" update
            sudo dpkg --add-architecture i386
            sudo "$PACKAGER" update
            sudo "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS 
            ;;
        dnf)
            COMPILEDEPS='@development-tools'
            sudo "$PACKAGER" update
            sudo "$PACKAGER" config-manager --set-enabled powertools
            sudo "$PACKAGER" install -y "$DEPENDENCIES" $COMPILEDEPS
            sudo "$PACKAGER" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            sudo "$PACKAGER" refresh 
            sudo "$PACKAGER" --non-interactive install "$DEPENDENCIES" $COMPILEDEPS
            sudo "$PACKAGER" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        *)
            sudo "$PACKAGER" install -y $DEPENDENCIES # Fixed bug where no packages found on debian-based
            ;;
    esac
}

install_additional_dependencies() {
    case $(command -v apt || command -v zypper || command -v dnf || command -v pacman) in
        *apt)
            # Add additional dependencies for apt if needed
            ;;
        *zypper)
            # Add additional dependencies for zypper if needed
            ;;
        *dnf)
            # Add additional dependencies for dnf if needed
            ;;
        *pacman)
            # Add additional dependencies for pacman if needed
            ;;
        *)
            # Add additional dependencies for other package managers if needed
            ;;
    esac
}

checkEnv
installDepend
install_additional_dependencies
