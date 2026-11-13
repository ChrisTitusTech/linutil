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
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive com.retrodev.blastem
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
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}blastem is not installed.${RC}"
	fi
}

main() {
    installblastem
}

checkEnv
main