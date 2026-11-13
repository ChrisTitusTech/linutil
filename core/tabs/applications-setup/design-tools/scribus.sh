#!/bin/sh -e

. ../../common-script.sh

installScribus() {
	printf "%b\n" "${YELLOW}Installing Scribus...${RC}"
	if ! command_exists scribus; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y scribus
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter scribus
	            ;;
	        *)
				checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive net.scribus.Scribus
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Scribus is already installed.${RC}"
	fi
}

uninstallScribus() {
	printf "%b\n" "${YELLOW}Uninstalling Scribus...${RC}"
	if command_exists scribus; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y scribus
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter scribus
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive net.scribus.Scribus
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Scribus is not installed.${RC}"
	fi
}

main() {
    installScribus
}

checkEnv
main