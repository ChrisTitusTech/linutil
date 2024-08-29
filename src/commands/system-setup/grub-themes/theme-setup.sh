#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

installGit() {

    echo -e "Checking git..."
            if ! command_exists git; then
            echo -e "${GREEN}Installing git${RC}"
    case $PACKAGER in
        pacman)
            $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm git
            ;;
        apt-get|nala)
            $ESCALATION_TOOL "$PACKAGER" install -y git
            ;;
        dnf)
            $ESCALATION_TOOL "$PACKAGER" install -y git
            ;;
        zypper)
            $ESCALATION_TOOL "$PACKAGER" --non-interactive install git
            ;;
        *)
            echo -e "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac

    else
            echo "git already installed"
            fi
}

GrubThemes() {

echo -e "${GREEN}Adding GRUB theme${RC}"
THEME_REPO="https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git"

themes=("CyberRe" "Cyberpunk" "Shodan" "Vimix" "fallout")


# Display the menu for theme selection
echo "Select a theme to use:"
select theme in "${themes[@]}" "Quit"; do
    case $theme in
        "Quit")
            echo "No theme selected. Exiting."
            exit 0
            ;;
        *)
            if [[ -n $theme ]]; then
    
            
            THEME_DIR="/boot/grub/themes/$theme"

            if [ ! -d "${THEME_DIR}" ]; then
                
                $ESCALATION_TOOL mkdir -p "${THEME_DIR}"
                cd "${THEME_DIR}" || exit
                
                # Clone the specific theme using sparse checkout
                $ESCALATION_TOOL git init
                $ESCALATION_TOOL git remote add -f origin $THEME_REPO
                $ESCALATION_TOOL git config core.sparseCheckout true
                echo "themes/$theme/*" | $ESCALATION_TOOL tee -a .git/info/sparse-checkout
                $ESCALATION_TOOL git pull origin main
                $ESCALATION_TOOL mv themes/$theme/* $THEME_DIR
                $ESCALATION_TOOL rm -rf themes
                $ESCALATION_TOOL rm -rf .git
            fi
                # Add the theme to the GRUB configuration
                $ESCALATION_TOOL sed -i "/^GRUB_THEME=/d" /etc/default/grub
                echo "GRUB_THEME=\"$THEME_DIR/theme.txt\"" | $ESCALATION_TOOL tee -a /etc/default/grub
            else
                echo "Invalid selection."
                 exit 0
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
            $ESCALATION_TOOL update-grub
            ;;
        yum|dnf|zypper)
            $ESCALATION_TOOL grub2-mkconfig -o /boot/grub2/grub.cfg
            ;;
        pacman|xbps-install)
            $ESCALATION_TOOL grub-mkconfig -o /boot/grub/grub.cfg
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

checkPackageManager 'apt-get nala dnf pacman zypper yum xbps-install nix-env'
checkEscalationTool
installGit
GrubThemes
updateGrub
