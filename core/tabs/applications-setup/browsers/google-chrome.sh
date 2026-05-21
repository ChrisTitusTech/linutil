#!/bin/sh -e

. ../../common-script.sh

installChrome() {
    if ! command_exists google-chrome; then
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
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled google-chrome
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
    if command_exists google-chrome; then
        printf "%b\n" "${YELLOW}Uninstalling Google Chrome...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" purge --autoremove -y google-chrome
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive uninstall google-chrome-stable
                ;;
            pacman)
                "$AUR_HELPER" -Rns --needed --noconfirm google-chrome
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y google-chrome-stable
                ;;
            *)
                "$ESCALATION_TOOL" flatpak uninstall --noninteractive com.google.Chrome
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Google Chrome Browser is already installed.${RC}"
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
