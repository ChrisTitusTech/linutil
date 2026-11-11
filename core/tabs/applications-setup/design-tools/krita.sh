#!/bin/sh -e

. ../../common-script.sh

installKrita() {
	printf "%b\n" "${YELLOW}Installing Krita...${RC}"
	if ! command_exists krita; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y krita
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter krita
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.kde.krita
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Krita is already installed.${RC}"
	fi
}

uninstallKrita() {
	printf "%b\n" "${YELLOW}Uninstalling Krita...${RC}"
	if command_exists krita; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y krita
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter krita
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.kde.krita
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Krita is not installed.${RC}"
	fi
}

main() {
    installKrita
}

checkEnv
main