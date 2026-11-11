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
				checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.flycast.Flycast
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
	        	"$ESCALATION_TOOL" flatpak uninstall --noninteractive opp.flycast.Flycast
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}flycast is not installed.${RC}"
	fi
}

main() {
    installflycast
}

checkEnv
main