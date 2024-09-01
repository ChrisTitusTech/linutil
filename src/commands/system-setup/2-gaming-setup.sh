#!/bin/sh -e

. ../common-script.sh

installDepend() {
    ## Check for dependencies.
    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
            echo "[multilib]" | $ESCALATION_TOOL tee -a /etc/pacman.conf
            echo "Include = /etc/pacman.d/mirrorlist" | $ESCALATION_TOOL tee -a /etc/pacman.conf
            $ESCALATION_TOOL ${PACKAGER} -Syu
        else
            echo "Multilib is already enabled."
        fi
        if ! command_exists yay && ! command_exists paru; then
            echo "Installing yay as AUR helper..."
            $ESCALATION_TOOL ${PACKAGER} -S --needed --noconfirm base-devel
            cd /opt && $ESCALATION_TOOL git clone https://aur.archlinux.org/yay-git.git && $ESCALATION_TOOL chown -R ${USER}:${USER} ./yay-git
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
        $AUR_HELPER -S --needed --noconfirm wine giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
ncurses lib32-ncurses ocl-icd lib32-ocl-icd libxslt lib32-libxslt libva lib32-libva gtk3 \
lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
    elif [ "$PACKAGER" = "apt-get" ]; then
        $ESCALATION_TOOL ${PACKAGER} update
        $ESCALATION_TOOL ${PACKAGER} install -y wine64 wine32 libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386
    elif [ "$PACKAGER" = "dnf" ] || [ "$PACKAGER" = "zypper" ]; then
        $ESCALATION_TOOL ${PACKAGER} install -y wine
    else
        $ESCALATION_TOOL ${PACKAGER} install -y ${DEPENDENCIES}
    fi
}

install_additional_dependencies() {
    case $(command -v apt-get || command -v zypper || command -v dnf || command -v pacman) in
        *apt-get)
            version=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/lutris/lutris |
                grep -v 'beta' |
                tail -n1 |
                cut -d '/' --fields=3)

            version_no_v=$(echo "$version" | tr -d v)
            wget "https://github.com/lutris/lutris/releases/download/${version}/lutris_${version_no_v}_all.deb"

            # Install the downloaded .deb package using apt-get
            echo "Installing lutris_${version_no_v}_all.deb"
            $ESCALATION_TOOL apt-get update
            $ESCALATION_TOOL apt-get install ./lutris_${version_no_v}_all.deb

            # Clean up the downloaded .deb file
            rm lutris_${version_no_v}_all.deb

            echo "Lutris Installation complete."
            echo "Installing steam..."

            #Install steam on Debian
            if (lsb_release -i  | grep -qi Debian); then
                #Enable i386 repos
                $ESCALATION_TOOL dpkg --add-architecture i386
                # Install software-properties-common to be able to add repos
                $ESCALATION_TOOL apt-get install -y software-properties-common 
                # Add repos necessary for installing steam
                $ESCALATION_TOOL apt-add-repository contrib -y
                $ESCALATION_TOOL apt-add-repository non-free -y
                #Install steam
                $ESCALATION_TOOL apt-get install steam-installer -y
            else
            #Install steam on Ubuntu
                $ESCALATION_TOOL apt-get install -y steam
            fi
            ;;
        *zypper)

            ;;
        *dnf)

            ;;
        *pacman)
            echo "Installing Steam for Arch Linux..."
            $ESCALATION_TOOL pacman -S --needed --noconfirm steam
            echo "Steam installation complete."
            
            echo "Installing Lutris for Arch Linux..."
            $ESCALATION_TOOL pacman -S --needed --noconfirm lutris
            echo "Lutris installation complete."
            
            echo "Installing GOverlay for Arch Linux..."
            $ESCALATION_TOOL pacman -S --needed --noconfirm goverlay
            echo "GOverlay installation complete."
            ;;
        *)

          ;;
    esac
}

checkEnv
checkEscalationTool
installDepend
install_additional_dependencies
