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
	            exit 1
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
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xenia is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall xenia${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installxenia ;;
        2) uninstallxenia ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main