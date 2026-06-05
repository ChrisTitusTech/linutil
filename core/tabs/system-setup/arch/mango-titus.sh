#!/bin/sh

. ../../common-script.sh
. ../../common-service-script.sh

install_mango_titus() {
    printf "%b\n" "${YELLOW}Installing Mango-Titus...${RC}"

    if ! command_exists mango; then
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm --cleanafter mangowm
                ;;
            *)
                printf "${GREEN}Unsupported Package Manager: $PACKAGER${RC}"
                ;;
        esac
    fi

    MANGO_DIR="$HOME/.config/mango/"

    # Create directory if needed
    [ ! -d "$HOME/.config/share" ] && mkdir -p "$HOME/.config/"

    # Clone or update mango-titus repository
    if [ ! -d "$MANGO_DIR" ]; then
        printf "%b\n" "${YELLOW}Cloning Mango-titus repository...${RC}"
        git clone https://github.com/ChrisTitusTech/mango-titus.git "$MANGO_DIR" || {
            printf "%b\n" "${RED}Failed to clone mango-titus${RC}"
            return 1
        }
    else
        printf "%b\n" "${YELLOW}Updating Mango-titus repository...${RC}"
        if cd "$MANGO_DIR" && git pull; then
            :
        else
            printf "%b\n" "${RED}Failed to update Mango-titus${RC}"
            return 1
        fi
    fi

    printf "%b\n" "${GREEN}Mango-Titus installation complete${RC}"
}

uninstall_mango_titus() {
    printf "%b\n" "${YELLOW}Uninstalling Mango-Titus...${RC}"

    if command_exists mango; then

        $"AUR_HELPER" -Rns --noconfirm --cleanafter mangowm

        MANGO_DIR="$HOME/.config/mango/"
        if [ -d "$MANGO_DIR" ]; then
            sudo rm -rf "$HOME/.confg/mango"
        fi
    else
        printf "${YELLOW}MangoWM is not installed${RC}"
    fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Mango-Titus${RC}"
    printf "%b\n" "1. ${YELLOW}Install Mango-Titus repos${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall Mango-Titus repo${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) install_mango_titus ;;
        2) uninstall_mango_titus ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
main
