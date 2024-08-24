#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

echo -e "Installing Shodan GRUB theme..."
THEME_DIR="/boot/grub/themes/Shodan"
echo -e "Creating the theme directory..."
sudo mkdir -p "${THEME_DIR}"

# Clone the theme
cd "${THEME_DIR}" || exit
sudo git init
sudo git remote add -f origin https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
sudo git config core.sparseCheckout true
echo "themes/Shodan/*" | sudo tee -a .git/info/sparse-checkout
sudo git pull origin main
sudo mv themes/Shodan/* .
sudo rm -rf themes
sudo rm -rf .git

echo "Shodan theme has been cloned to ${THEME_DIR}"
echo -e "Backing up GRUB config..."
sudo cp -an /etc/default/grub /etc/default/grub.bak
echo -e "Setting the theme as the default..."
# Remove any existing GRUB_THEME lines
sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub
# Append the new GRUB_THEME line
echo "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" | sudo tee -a /etc/default/grub
echo -e "Updating GRUB..."



updateGrub() {
    echo -e "${GREEN}Updating GRUB...${RC}"

    case "${PACKAGER}" in
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