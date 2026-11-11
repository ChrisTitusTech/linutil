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
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive com.snes9x.Snes9x
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
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}snes9x is not installed.${RC}"
	fi
}

main() {
    installsnes9x
}

checkEnv
main