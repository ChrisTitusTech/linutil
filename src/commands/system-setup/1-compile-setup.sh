#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo -e "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo -e "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

if [ ! -d "$LINUXTOOLBOXDIR/linux-setup" ]; then
    echo -e "${YELLOW}Cloning linux-setup repository into: $LINUXTOOLBOXDIR/linux-setup${RC}"
    git clone https://github.com/ChrisTitusTech/linux-setup "$LINUXTOOLBOXDIR/linux-setup"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully cloned linux-setup repository${RC}"
    else
        echo -e "${RED}Failed to clone linux-setup repository${RC}"
        exit 1
    fi
fi

cd "$LINUXTOOLBOXDIR/linux-setup" || exit

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

GITPATH="$(dirname "$(realpath "$0")")"
if [ ! -w "$GITPATH" ]; then
    echo "${RED}Can't write to $GITPATH${RC}"
    exit 1
fi

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    echo "${YELLOW}Installing dependencies...${RC}"
    case $PKGR in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | sudo tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
                sudo "$PKGR" -Sy
            else
                echo "Multilib is already enabled."
            fi
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                sudo "$PKGR" --noconfirm -S base-devel
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
            sudo "$PKGR" update
            sudo dpkg --add-architecture i386
            sudo "$PKGR" update
            sudo "$PKGR" install -y $DEPENDENCIES $COMPILEDEPS
            ;;
        dnf)
            COMPILEDEPS='@development-tools'
            sudo "$PKGR" update
            sudo "$PKGR" config-manager --set-enabled powertools
            sudo "$PKGR" install -y $DEPENDENCIES $COMPILEDEPS
            sudo "$PKGR" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            sudo "$PKGR" refresh
            sudo "$PKGR" --non-interactive install $DEPENDENCIES $COMPILEDEPS
            sudo "$PKGR" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        *)
            sudo "$PKGR" install -y $DEPENDENCIES
            ;;
    esac
}

install_additional_dependencies() {
    case "$PKGR" in
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

installDepend
install_additional_dependencies
