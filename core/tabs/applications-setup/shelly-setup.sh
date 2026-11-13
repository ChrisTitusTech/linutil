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
    installShelly
}

checkEnv
main
