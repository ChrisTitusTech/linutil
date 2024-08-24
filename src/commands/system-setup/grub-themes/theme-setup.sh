#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

installGit() {
    echo -e "${GREEN}Checking git...${RC}"
            if ! command_exists git; then
                echo -e "${GREEN}Installing git${RC}"
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    case $PACKAGER in
        pacman)
            sudo "$PACKAGER" -S --needed --noconfirm git
            ;;
        apt-get|nala)
            sudo "$PACKAGER" install -y git
            ;;
        dnf)
            sudo "$PACKAGER" install -y git
            ;;
        zypper)
            sudo "$PACKAGER" --non-interactive install git
            ;;
        *)
            echo "No known package manager detected. Cannot install Git."
            exit 1
            ;;
    esac

    else
            echo "git already installed"
            fi
}

GrubThemes() {
clear
echo -e "${GREEN}Adding GRUB theme${RC}"
THEME_REPO="https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git"

themes=("CyberRe" "Cyberpunk" "Shodan" "Vimix" "fallout")


# Display the menu for theme selection
echo "Select a theme to add:"
select theme in "${themes[@]}" "Quit"; do
    case $theme in
        "Quit")
            echo "No theme selected. Exiting."
            exit 0
            ;;
        *)
            if [[ -n $theme ]]; then
              
            THEME_DIR="/boot/grub/themes/$theme"

            if [ -d "${THEME_DIR}" ]; then
               sudo cp -r "${THEME_DIR}" "${THEME_DIR}"-bak
            fi
                sudo mkdir -p "${THEME_DIR}"

                cd "${THEME_DIR}" || exit
                
                # Clone the specific theme using sparse checkout
                sudo git init
                sudo git remote add -f origin https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
                sudo git config core.sparseCheckout true
                echo "themes/$theme/*" | sudo tee -a .git/info/sparse-checkout
                sudo git pull origin main
                sudo mv themes/$theme/* .
                sudo rm -rf themes
                sudo rm -rf .git

                echo "Added theme: $theme"

                # Add the theme to the GRUB configuration
                sudo sed -i "/^GRUB_THEME=/d" /etc/default/grub
                echo "GRUB_THEME=\"$THEME_DIR/theme.txt\"" | sudo tee -a /etc/default/grub
            else
                echo "Invalid selection."
            fi
            break
            ;;
    esac
done
}

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
            echo -e "${RED}Manually update GRUB${RC}"
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
installGit
GrubThemes
updateGrub
