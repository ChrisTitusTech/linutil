#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

checkGrubIsInstalled() {
    if ! command_exists update-grub && \
       ! command_exists grub2-mkconfig && \
       ! command_exists grub-mkconfig; then
        echo "GRUB is not installed."
        exit 1
    fi
}


removingGrubTheme(){

echo -e "${GREEN}Removing GRUB themes${RC}"

    if [[ -d "/boot/grub" ]]; then
        GRUB_DIR='/boot/grub'
    elif [[ -d "/boot/grub2" ]]; then
        GRUB_DIR='/boot/grub2'
    else
        echo "GRUB directory not found. Exiting."
        exit 1
    fi

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
    exit 1
fi

# Display the menu for theme selection
echo "Select a theme to remove:"
select theme in "${existing_themes[@]}" "Quit"; do
    case $theme in
        "Quit")
            echo "No theme selected. press <ENTER>."
            exit 0
            ;;
        *)
            if [[ -n $theme ]]; then
                theme_dir="${GRUB_DIR}/themes/${theme}"
                $ESCALATION_TOOL rm -rf "$theme_dir"
                echo "Removed theme: $theme"
            else
                echo "Invalid selection."
                exit 1
            fi
            break
            ;;
    esac
done

$ESCALATION_TOOL sed -i "/^GRUB_THEME=/d" /etc/default/grub
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
        pacman)
            $ESCALATION_TOOL grub-mkconfig -o /boot/grub/grub.cfg
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


checkGrubIsInstalled
checkPackageManager 'apt-get nala dnf pacman zypper yum'
checkEscalationTool
removingGrubTheme
updateGrub