#!/bin/sh -e

. ../../common-script.sh

installGIMP() {
	printf "%b\n" "${YELLOW}Installing GIMP...${RC}"
	if ! command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y gimp
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter gimp
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.gimp.GIMP
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is already installed.${RC}"
	fi
}

uninstallGIMP() {
	printf "%b\n" "${YELLOW}Uninstalling GIMP...${RC}"
	if command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y gimp
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter gimp
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.gimp.GIMP
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is not installed.${RC}"
	fi
}

main() {
    installGIMP
}

checkEnv
main
