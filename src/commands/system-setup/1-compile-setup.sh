#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

if [ ! -d "$LINUXTOOLBOXDIR/linux-setup" ]; then
    echo "${YELLOW}Cloning linux-setup repository into: $LINUXTOOLBOXDIR/linux-setup${RC}"
    git clone https://github.com/ChrisTitusTech/linux-setup "$LINUXTOOLBOXDIR/linux-setup"
    if [ $? -eq 0 ]; then
        echo "${GREEN}Successfully cloned linux-setup repository${RC}"
    else
        echo "${RED}Failed to clone linux-setup repository${RC}"
        exit 1
    fi
fi

cd "$LINUXTOOLBOXDIR/linux-setup" || exit

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            echo "${RED}To run me, you need: $REQUIREMENTS${RC}"
            exit 1
        fi
    done

    ## Check Package Manager
    PACKAGEMANAGER='apt yum dnf pacman zypper'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            echo "Using $pgm"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        echo "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            echo "Super user group $SUGROUP"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    echo "${YELLOW}Installing dependencies...${RC}"
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
            "$AUR_HELPER" --noconfirm -S $DEPENDENCIES
            ;;
        apt)
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
            sudo "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS
            sudo "$PACKAGER" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            sudo "$PACKAGER" refresh 
            sudo "$PACKAGER" --non-interactive install $DEPENDENCIES $COMPILEDEPS
            sudo "$PACKAGER" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        *)
            sudo "$PACKAGER" install -y $DEPENDENCIES
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