#!/bin/sh -e

. ../common-script.sh

installDepend() {
    # Check for dependencies
    DEPENDENCIES='wine dbus'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            #Check for multilib
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | elevated_execution tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | elevated_execution tee -a /etc/pacman.conf
                elevated_execution "$PACKAGER" -Syu
            else
                printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
            fi

            DISTRO_DEPS="gnutls lib32-gnutls base-devel gtk2 gtk3 lib32-gtk2 lib32-gtk3 libpulse lib32-libpulse alsa-lib lib32-alsa-lib \
                alsa-utils alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib giflib lib32-giflib libpng lib32-libpng \
                libldap lib32-libldap openal lib32-openal libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama \
                ncurses lib32-ncurses vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd libva lib32-libva \
                gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2"

            $AUR_HELPER -S --needed --noconfirm $DEPENDENCIES $DISTRO_DEPS
            ;;
        apt-get|nala)
            DISTRO_DEPS="libasound2 libsdl2 wine64 wine32"

            elevated_execution "$PACKAGER" update
            elevated_execution dpkg --add-architecture i386
            elevated_execution "$PACKAGER" install -y software-properties-common
            elevated_execution apt-add-repository contrib -y
            elevated_execution "$PACKAGER" update
            elevated_execution "$PACKAGER" install -y $DEPENDENCIES $DISTRO_DEPS
            ;;
        dnf)
            if [ "$(rpm -E %fedora)" -le 41 ]; then 
                elevated_execution "$PACKAGER" install ffmpeg ffmpeg-libs -y
                elevated_execution "$PACKAGER" install -y $DEPENDENCIES
            else
                printf "%b\n" "${CYAN}Fedora < 41 detected. Installing rpmfusion repos.${RC}"
                elevated_execution "$PACKAGER" install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm -y
                elevated_execution "$PACKAGER" config-manager --enable fedora-cisco-openh264 -y
                elevated_execution "$PACKAGER" install -y $DEPENDENCIES
            fi
            ;;
        zypper)
            elevated_execution "$PACKAGER" -n install $DEPENDENCIES
            ;;
        *)
            elevated_execution "$PACKAGER" install -y $DEPENDENCIES
            ;;
    esac
}

installAdditionalDepend() {
    case "$PACKAGER" in
        pacman)
            DISTRO_DEPS='steam lutris goverlay'
            elevated_execution "$PACKAGER" -S --needed --noconfirm $DISTRO_DEPS
            ;;
        apt-get|nala)
            version=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/lutris/lutris |
                grep -v 'beta' |
                tail -n1 |
                cut -d '/' --fields=3)

            version_no_v=$(echo "$version" | tr -d v)
            curl -sSLo "lutris_${version_no_v}_all.deb" "https://github.com/lutris/lutris/releases/download/${version}/lutris_${version_no_v}_all.deb"
            
            printf "%b\n" "${YELLOW}Installing Lutris...${RC}"
            elevated_execution "$PACKAGER" install ./lutris_"${version_no_v}"_all.deb

            rm lutris_"${version_no_v}"_all.deb

            printf "%b\n" "${GREEN}Lutris Installation complete.${RC}"
            printf "%b\n" "${YELLOW}Installing steam...${RC}"

            if lsb_release -i | grep -qi Debian; then
                elevated_execution apt-add-repository non-free -y
                elevated_execution "$PACKAGER" install steam-installer -y
            else
                elevated_execution "$PACKAGER" install -y steam
            fi
            ;;
        dnf)
            DISTRO_DEPS='steam lutris'
            elevated_execution "$PACKAGER" install -y $DISTRO_DEPS
            ;;
        zypper)
            # Flatpak
            DISTRO_DEPS='lutris'
            elevated_execution "$PACKAGER" -n install $DISTRO_DEPS
            ;;
        *)
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend
installAdditionalDepend
