#!/bin/sh -e

. ../../../common-script.sh

installkronos() {
	printf "%b\n" "${YELLOW}Installing kronos...${RC}"
	if ! command_exists kronos; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter kronos
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}kronos is already installed.${RC}"
	fi
}

uninstallkronos() {
	printf "%b\n" "${YELLOW}Uninstalling kronos...${RC}"
	if command_exists kronos; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter kronos
	            ;;
	        *)
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}kronos is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall kronos${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installkronos ;;
        2) uninstallkronos ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main