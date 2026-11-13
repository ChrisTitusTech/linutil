#!/bin/sh -e

. ../../../common-script.sh

installbsnes() {
	printf "%b\n" "${YELLOW}Installing bsnes...${RC}"
	if ! command_exists bsnes; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter bsnes-hd
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive dev.bsnes.bsnes
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}bsnes is already installed.${RC}"
	fi
}

uninstallbsnes() {
	printf "%b\n" "${YELLOW}Uninstalling bsnes...${RC}"
	if command_exists bsnes; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter bsnes-hd
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive dev.bsnes.bsnes
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}bsnes is not installed.${RC}"
	fi
}

main() {
    installbsnes
}

checkEnv
main