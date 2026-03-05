#!/bin/sh -e

. ../../../common-script.sh

installflycast() {
	printf "%b\n" "${YELLOW}Installing flycast...${RC}"
	if ! command_exists flycast; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter flycast
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.flycast.Flycast
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}flycast is already installed.${RC}"
	fi
}

uninstallflycast() {
	printf "%b\n" "${YELLOW}Uninstalling flycast...${RC}"
	if command_exists flycast; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter flycast
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak install --noninteractive opp.flycast.Flycast
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}flycast is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall flycast" installflycast uninstallflycast
}

checkEnv
main
