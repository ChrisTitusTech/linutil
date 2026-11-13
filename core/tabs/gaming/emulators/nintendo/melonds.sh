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
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive net.kuribo64.melonDS
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
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MelonDS is not installed.${RC}"
	fi
}

main() {
    installMelonDS
}

checkEnv
main