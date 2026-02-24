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
	run_install_uninstall_menu "Do you want to Install or Uninstall kronos" installkronos uninstallkronos
}

checkEnv
main
