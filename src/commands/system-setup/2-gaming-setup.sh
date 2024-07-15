#!/bin/sh -e

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'

command_exists() {
    command -v $1 >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    if ! command_exists ${REQUIREMENTS}; then
        echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
        exit 1
    fi

    ## Check Package Handeler
    PACKAGEMANAGER='apt-get yum dnf pacman zypper'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo -e "Using ${pgm}"
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager"
        exit 1
    fi

    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(readlink -f "$0")")"
    if [ ! -w ${GITPATH} ]; then
        echo -e "${RED}Can't write to ${GITPATH}${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep ${sug}; then
            SUGROUP=${sug}
            echo -e "Super user group ${SUGROUP}"
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep ${SUGROUP} >/dev/null; then
        echo -e "${RED}You need to be a member of the sudo group to run me!"
        exit 1
    fi

}

installDepend() {
    ## Check for dependencies.
    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
            echo "[multilib]" | sudo tee -a /etc/pacman.conf
            echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
            sudo ${PACKAGER} -Sy
        else
            echo "Multilib is already enabled."
        fi
        if ! command_exists yay && ! command_exists paru; then
            echo "Installing yay as AUR helper..."
            sudo ${PACKAGER} --noconfirm -S base-devel
            cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git
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
        ${AUR_HELPER} --noconfirm -S wine giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
ncurses lib32-ncurses ocl-icd lib32-ocl-icd libxslt lib32-libxslt libva lib32-libva gtk3 \
lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
    elif [ "$PACKAGER" = "apt-get" ]; then
        sudo ${PACKAGER} update
        sudo ${PACKAGER} install -y wine64 wine32 libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386
    elif [ "$PACKAGER" = "dnf" ] || [ "$PACKAGER" = "zypper" ]; then
        sudo ${PACKAGER} install -y wine
    else
        sudo ${PACKAGER} install -y ${DEPENDENCIES}
    fi
}

install_additional_dependencies() {
    case $(which apt-get || which zypper || which dnf || which pacman) in
        *apt-get)
            version=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/lutris/lutris |
                grep -v 'beta' |
                tail -n1 |
                cut -d '/' --fields=3)

            version_no_v=$(echo "$version" | tr -d v)
            wget "https://github.com/lutris/lutris/releases/download/${version}/lutris_${version_no_v}_all.deb"

            # Install the downloaded .deb package using apt-get
            echo "Installing lutris_${version_no_v}_all.deb"
            sudo apt-get update
            sudo apt-get install ./lutris_${version_no_v}_all.deb

            # Clean up the downloaded .deb file
            rm lutris_${version_no_v}_all.deb

            echo "Lutris Installation complete."
            echo "Installing steam..."
            sudo apt-get install -y steam
            ;;
        *zypper)
            
            ;;
        *dnf)
            
            ;;
        *pacman)
            
            ;;
        *)
            
            ;;
    esac
}

checkEnv
installDepend
install_additional_dependencies