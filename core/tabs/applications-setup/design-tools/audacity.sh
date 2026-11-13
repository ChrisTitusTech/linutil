#!/bin/sh -e

. ../../common-script.sh

installAudacity() {
	printf "%b\n" "${YELLOW}Installing Audacity...${RC}"
	if ! command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y audacity
	            ;;
	        pacman)
				"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm --cleanafter audacity
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.audacityteam.Audacity
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is already installed.${RC}"
	fi
}

uninstallAudacity() {
	printf "%b\n" "${YELLOW}Uninstalling Audacity...${RC}"
	if command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y audacity
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter audacity
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.audacityteam.Audacity
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is not installed.${RC}"
	fi
}

main() {
    installAudacity
}

checkEnv
main