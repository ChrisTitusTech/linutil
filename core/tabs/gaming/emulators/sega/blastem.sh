#!/bin/sh -e

. ../../../common-script.sh

installblastem() {
	printf "%b\n" "${YELLOW}Installing blastem...${RC}"
	if ! command_exists blastem; then
	    case "$PACKAGER" in
	        apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y blastem
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter blastem
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive com.retrodev.blastem
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}blastem is already installed.${RC}"
	fi
}

uninstallblastem() {
	printf "%b\n" "${YELLOW}Uninstalling blastem...${RC}"
	if command_exists blastem; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y blastem
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter blastem
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive com.retrodev.blastem
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}blastem is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall blastem" installblastem uninstallblastem
}

checkEnv
main
