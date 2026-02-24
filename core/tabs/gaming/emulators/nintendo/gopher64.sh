#!/bin/sh -e

. ../../../common-script.sh

installgopher64() {
	printf "%b\n" "${YELLOW}Installing gopher64plus...${RC}"
	if ! command_exists gopher64plus; then
	    case "$PACKAGER" in
	        apt-get|nala)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y gopher64
	        	;;
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y gopher64
	        	;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter gopher64
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive io.github.gopher64.gopher64
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}gopher64 is already installed.${RC}"
	fi
}

uninstallgopher64() {
	printf "%b\n" "${YELLOW}Uninstalling gopher64plus...${RC}"
	if command_exists gopher64plus; then
	    case "$PACKAGER" in
	    	apt-get|nala)
	        	"$ESCALATION_TOOL" "$PACKAGER" uninstall -y gopher64
	        	;;
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" uninstall -y gopher64
	        	;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter gopher64
	            ;;
	        *)
	            if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak uninstall --noninteractive io.github.gopher64.gopher64
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}gopher64plus is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall gopher64" installgopher64 uninstallgopher64
}

checkEnv
main

