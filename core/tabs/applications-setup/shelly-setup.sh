#!/bin/sh -e

. ../common-script.sh

installShelly() {
	printf "%b\n" "${YELLOW}Installing Shelly...${RC}"
	if ! command_exists shelly; then
	    case "$PACKAGER" in
	        pacman)
				"$AUR_HELPER" -S --needed --noconfirm --cleanafter shelly
	            ;;
	        *)
                printf "%b\n" "${RED}Unsupported Packager Manager: $PACKAGER${RC}"
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Shelly is already installed.${RC}"
	fi
}

uninstallShelly() {
	printf "%b\n" "${YELLOW}Uninstalling Shelly...${RC}"
	if command_exists shelly; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -Rns --noconfirm --cleanafter audacity
	            ;;
	        *)
                printf "%b\n" "${RED}Unsupported Packager Manager: $PACKAGER${RC}"
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Shelly is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Shelly${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installShelly ;;
        2) uninstallShelly ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
main
