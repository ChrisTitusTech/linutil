#!/bin/sh -e

. ../../../common-script.sh

installxemu() {
	printf "%b\n" "${YELLOW}Installing xemu...${RC}"
	if ! command_exists xemu; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter xemu-bin
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive app.xemu.xemu
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xemu is already installed.${RC}"
	fi
}

uninstallxemu() {
	printf "%b\n" "${YELLOW}Uninstalling xemu...${RC}"
	if command_exists xemu; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter xemu-bin
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak install --noninteractive app.xemu.xemu
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xemu is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall xemu" installxemu uninstallxemu
}

checkEnv
main
