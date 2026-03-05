#!/bin/sh -e

. ../../../common-script.sh

installMelonDS() {
	printf "%b\n" "${YELLOW}Installing MelonDS...${RC}"
	if ! command_exists melonDS; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter melonds-bin
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive net.kuribo64.melonDS
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MelonDS is already installed.${RC}"
	fi
}

uninstallMelonDS() {
	printf "%b\n" "${YELLOW}Uninstalling MelonDS...${RC}"
	if command_exists melonDS; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter melonds-bin
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive net.kuribo64.melonDS
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MelonDS is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall MelonDS" installMelonDS uninstallMelonDS
}

checkEnv
main
