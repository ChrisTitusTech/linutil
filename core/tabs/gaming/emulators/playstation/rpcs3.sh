#!/bin/sh -e

. ../../../common-script.sh

installrpcs3() {
	printf "%b\n" "${YELLOW}Installing RPCS3...${RC}"
	if ! command_exists rpcs3; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter rpcs3-bin
	            ;;
	        *)
				checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive net.rpcs3.RPCS3
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RPCS3 is already installed.${RC}"
	fi
}

uninstallrpcs3() {
	printf "%b\n" "${YELLOW}Uninstalling RPCS3...${RC}"
	if command_exists rpcs3; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter rpcs3-bin
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak uninstall --noninteractive net.rpcs3.RPCS3
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RPCS3 is not installed.${RC}"
	fi
}

main() {
    installrpcs3
}

checkEnv
main