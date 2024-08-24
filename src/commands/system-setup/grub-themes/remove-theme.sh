#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"


    echo -e "${GREEN}Removing GRUB themes${RC}"
    GRUB_DIR="/boot/grub"

cd "${GRUB_DIR}" || exit

themes=("CyberRe" "Cyberpunk" "Shodan" "Vimix" "fallout")

# Filter the list of themes to only include those that exist
existing_themes=()
for theme in "${themes[@]}"; do
    if [ -d "${GRUB_DIR}/themes/${theme}" ]; then
        existing_themes+=("$theme")
    fi
done

# Check if there are any existing themes
if [ ${#existing_themes[@]} -eq 0 ]; then
    echo "No themes found."
    exit 0
fi

# Display the menu for theme selection
echo "Select a theme to remove:"
select theme in "${existing_themes[@]}" "Quit"; do
    case $theme in
        "Quit")
            echo "No theme selected. Exiting."
            exit 0
            ;;
        *)
            if [[ -n $theme ]]; then
                theme_dir="${GRUB_DIR}/themes/${theme}"
                sudo rm -rf "$theme_dir"
                echo "Removed theme: $theme"
            else
                echo "Invalid selection."
            fi
            break
            ;;
    esac
done

sudo sed -i "/^GRUB_THEME=/d" /etc/default/grub

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