#!/bin/sh -e

. ../../../common-script.sh

installxenia() {
	printf "%b\n" "${YELLOW}Installing xenia...${RC}"
	if ! command_exists xenia; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter xenia-canary-bin
	            ;;
	        *)
	        	printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xenia is already installed.${RC}"
	fi
}

uninstallxenia() {
	printf "%b\n" "${YELLOW}Uninstalling xenia...${RC}"
	if command_exists xenia; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter xenia-canary-bin
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xenia is not installed.${RC}"
	fi
}

main() {
    installxenia
}

checkEnv
main