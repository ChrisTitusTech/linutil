#!/bin/sh -e

. ../../../common-script.sh

installRyujinx() {
	printf "%b\n" "${YELLOW}Installing Ryujinx...${RC}"
	if ! command_exists ryujinx; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter ryujinx
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive io.github.ryubing.Ryujinx
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ryujinx is already installed.${RC}"
	fi
}

uninstallRyujinx() {
	printf "%b\n" "${YELLOW}Uninstalling Ryujinx...${RC}"
	if command_exists ryujinx; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter ryujinx
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive io.github.ryubing.Ryujinx
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ryujinx is not installed.${RC}"
	fi
}

main() {
    installRyujinx
}

checkEnv
main