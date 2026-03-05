#!/bin/sh -e

. ../../../common-script.sh

installPCSX2() {
	printf "%b\n" "${YELLOW}Installing PCSX2...${RC}"
	if ! command_exists pcsx2; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter pcsx2
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive net.pcsx2.PCSX2
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}PCSX2 is already installed.${RC}"
	fi
}

uninstallPCSX2() {
	printf "%b\n" "${YELLOW}Uninstalling PCSX2...${RC}"
	if command_exists pcsx2; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter pcsx2
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak uninstall --noninteractive net.pcsx2.PCSX2
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}PCSX2 is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall PCSX2" installPCSX2 uninstallPCSX2
}

checkEnv
main
