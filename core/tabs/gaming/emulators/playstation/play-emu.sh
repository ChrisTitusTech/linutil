#!/bin/sh -e

. ../../../common-script.sh

installPlay() {
	printf "%b\n" "${YELLOW}Installing Play!...${RC}"
	if ! command_exists play-emu; then
	    case "$PACKAGER" in
	        # pacman)
	        # 	"$AUR_HELPER" -S --needed --noconfirm --cleanafter play-emu
	        #     ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.purei.Play
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Play! is already installed.${RC}"
	fi
}

uninstallPlay() {
	printf "%b\n" "${YELLOW}Uninstalling Play!...${RC}"
	if command_exists play-emu; then
	    case "$PACKAGER" in
	        # pacman)
			#     "$AUR_HELPER" -R --noconfirm --cleanafter play-emu
	        #     ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak uninstall --noninteractive org.purei.Play
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Play! is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall Play!" installPlay uninstallPlay
}

checkEnv
main
