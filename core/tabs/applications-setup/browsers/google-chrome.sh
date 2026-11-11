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
	printf "%b\n" "Google Chrome options:"
    printf "%b\n" "${YELLOW}1.${RC} Install"
    printf "%b\n" "${YELLOW}2.${RC} Remove Local AI (Prevents AI From Reinstalling)"
    printf "%b" "Enter your choice [1-2]: "
    CHOICE=''
    readMenuChoice CHOICE
    case "$CHOICE" in
        1) installChrome ;;
        2) removeLocalAI ;;
        *) invalidChoice ;;
    esac
}

checkEnv
main
