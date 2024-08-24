#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"


    echo -e "${GREEN}Removing GRUB themes${RC}"
THEME_DIR="/boot/grub/"

cd "${THEME_DIR}" || exit
sudo rm -rf themes/CyberRe
sudo rm -rf themes/Cyberpunk
sudo rm -rf themes/Shodan
sudo rm -rf themes/Vimix
sudo rm -rf themes/fallout

# Remove any existing GRUB_THEME lines
sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub

updateGrub() {
    echo -e "${GREEN}Updating GRUB...${RC}"

    case $PACKAGER in
        nala|apt-get)
            sudo update-grub
            ;;
        yum|dnf|zypper)
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg
            ;;
        pacman|xbps-install)
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            ;;
        *)
            echo -e "${RED}update GRUB manuli${RC}"
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}GRUB update successful.${RC}"
    else
        echo -e "${RED}GRUB update failed.${RC}"
        exit 1
    fi
}

checkEnv
updateGrub