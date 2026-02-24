#!/bin/sh -e

. ../../../common-script.sh

installsnes9x() {
	printf "%b\n" "${YELLOW}Installing snes9x...${RC}"
	if ! command_exists snes9x; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter snes9x-gtk
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive com.snes9x.Snes9x
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}snes9x is already installed.${RC}"
	fi
}

uninstallsnes9x() {
	printf "%b\n" "${YELLOW}Uninstalling snes9x...${RC}"
	if command_exists snes9x; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter snes9x-gtk
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive com.snes9x.Snes9x
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}snes9x is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall snes9x" installsnes9x uninstallsnes9x
}

checkEnv
main
