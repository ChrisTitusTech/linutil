#!/usr/bin/env sh

. ../common-script.sh
. ../common-service-script.sh

installDank() {
    printf "%b\n" "${YELLOW}Installing Dank Shell...${RC}"

    if ! command_exists dms; then
        curl -fsSL https://install.danklinux.com | sh
    else
        printf "%b\n" "${GREEN}Dank Shell already installed${RC}"
    fi

    printf "%b\n" "${GREEN}Dank Shell installation complete${RC}"
}

uninstallDank() {
    printf "%b\n" "${YELLOW}Uninstalling Dank Shell...${RC}"

    if command_exists dms; then
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -Rns --noconfirm --cleanafter dms-shell greetd-dms-greeter-git
                ;;
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y dms
            *)
                printf "%b\n" "${RED}Unsupported Package Manager: $PACKAGER${RC}"
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Dank Shell is not installed${RC}"
    fi

    printf "%b\n" "${GREEN}Dank Shell uninstall complete${RC}"
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Dank Shell${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installDank ;;
        2) uninstallDank ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
main
