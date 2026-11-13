#!/bin/sh -e

. ../../common-script.sh

checkChromeInstalled() {
    command_exists google-chrome || command_exists google-chrome-stable || command_exists com.google.Chrome
}

uninstallChromeFlatpak() {
    case "$1" in
        user)
            printf "%b\n" "${YELLOW}Uninstalling user Flatpak Google Chrome...${RC}"
            flatpak uninstall --user --noninteractive com.google.Chrome
            ;;
        system)
            printf "%b\n" "${YELLOW}Uninstalling system Flatpak Google Chrome...${RC}"
            "$ESCALATION_TOOL" flatpak uninstall --system --noninteractive com.google.Chrome
            ;;
    esac
}

uninstallChromeNative() {
    printf "%b\n" "${YELLOW}Uninstalling native Google Chrome...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" purge --autoremove -y google-chrome-stable
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive uninstall google-chrome-stable
            ;;
        pacman)
            "$AUR_HELPER" -Rns --noconfirm google-chrome
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" remove -y google-chrome-stable
            ;;
        *)
            printf "%b\n" "${RED}Native Google Chrome uninstall is not supported for ${PACKAGER}.${RC}"
            return 1
            ;;
    esac
}

installChrome() {
    if ! checkChromeInstalled; then
        printf "%b\n" "${YELLOW}Installing Google Chrome...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./google-chrome-stable_current_amd64.deb
                "$ESCALATION_TOOL" rm ./google-chrome-stable_current_amd64.deb
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install google-chrome-stable
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm --cleanafter google-chrome
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fedora-workstation-repositories
                fedora_version=$(rpm -E %fedora)
                if [ "$fedora_version" -ge 41 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt google-chrome.enabled=1
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled google-chrome
                fi
                "$ESCALATION_TOOL" "$PACKAGER" install -y google-chrome-stable
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive com.google.Chrome
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Google Chrome Browser is already installed.${RC}"
    fi
}

uninstallChrome() {
    native_installed=false
    user_flatpak_installed=false
    system_flatpak_installed=false
    if command_exists google-chrome || command_exists google-chrome-stable; then
        native_installed=true
    fi
    if command_exists flatpak; then
        if flatpak info --user com.google.Chrome >/dev/null 2>&1; then
            user_flatpak_installed=true
        fi
        if flatpak info --system com.google.Chrome >/dev/null 2>&1; then
            system_flatpak_installed=true
        fi
    fi

    installed_count=0
    [ "$native_installed" = true ] && installed_count=$((installed_count + 1))
    [ "$user_flatpak_installed" = true ] && installed_count=$((installed_count + 1))
    [ "$system_flatpak_installed" = true ] && installed_count=$((installed_count + 1))

    if [ "$installed_count" -eq 0 ]; then
        printf "%b\n" "${GREEN}Google Chrome Browser is not installed.${RC}"
    elif [ "$installed_count" -eq 1 ] && [ "$native_installed" = true ]; then
        uninstallChromeNative
    elif [ "$installed_count" -eq 1 ] && [ "$user_flatpak_installed" = true ]; then
        uninstallChromeFlatpak user
    elif [ "$installed_count" -eq 1 ]; then
        uninstallChromeFlatpak system
    else
        printf "%b\n" "${YELLOW}Multiple Google Chrome installations found. Which one do you want to uninstall?${RC}"
        next_choice=1
        native_choice=0
        user_flatpak_choice=0
        system_flatpak_choice=0
        if [ "$native_installed" = true ]; then
            native_choice=$next_choice
            printf "%b\n" "$next_choice. Native Google Chrome"
            next_choice=$((next_choice + 1))
        fi
        if [ "$user_flatpak_installed" = true ]; then
            user_flatpak_choice=$next_choice
            printf "%b\n" "$next_choice. User Flatpak Google Chrome"
            next_choice=$((next_choice + 1))
        fi
        if [ "$system_flatpak_installed" = true ]; then
            system_flatpak_choice=$next_choice
            printf "%b\n" "$next_choice. System Flatpak Google Chrome"
            next_choice=$((next_choice + 1))
        fi
        printf "%b\n" "$next_choice. Cancel"
        printf "%b" "Enter your choice [1-$next_choice]: "
        read -r uninstall_choice
        if [ "$uninstall_choice" = "$native_choice" ] && [ "$native_choice" -ne 0 ]; then
            uninstallChromeNative
        elif [ "$uninstall_choice" = "$user_flatpak_choice" ] && [ "$user_flatpak_choice" -ne 0 ]; then
            uninstallChromeFlatpak user
        elif [ "$uninstall_choice" = "$system_flatpak_choice" ] && [ "$system_flatpak_choice" -ne 0 ]; then
            uninstallChromeFlatpak system
        elif [ "$uninstall_choice" = "$next_choice" ]; then
            printf "%b\n" "${GREEN}Uninstall cancelled.${RC}"
        else
            printf "%b\n" "${RED}Invalid choice.${RC}"
            return 1
        fi
    fi
}

removeLocalAI() {
    # Set Chrome AI path
    CHROME_USER_DIR="$HOME/.config/google-chrome"

    # Path where Chrome AI model is stored
    AI_MODEL_DIR="$CHROME_USER_DIR/AI"

    # Remove AI model if it exists
    if [ -d "$AI_MODEL_DIR" ]; then
        echo "Removing existing Chrome AI model..."
        rm -rf "$AI_MODEL_DIR"
        echo "Removed AI model."
    else
        echo "No AI model found at $AI_MODEL_DIR"
    fi

    # Prevent re-download
    # Create an empty directory and make it read-only
    echo "Creating read-only placeholder to block AI download..."
    mkdir -p "$AI_MODEL_DIR"
    chmod 000 "$AI_MODEL_DIR"

    echo "Chrome AI model removed and blocked from redownloading."
}


main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Chrome${RC}"
    printf "%b\n" "1. ${YELLOW}Install Chrome${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall Chrome${RC}"
    printf "%b\n" "3. ${YELLOW}Remove Local AI (Prevents Chrome From Reinstalling)${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installChrome ;;
        2) uninstallChrome ;;
        3) removeLocalAI ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
main
