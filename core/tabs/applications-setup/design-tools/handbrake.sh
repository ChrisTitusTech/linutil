#!/bin/sh -e

. ../../common-script.sh

installHandbrake() {
	printf "%b\n" "${YELLOW}Installing Handbrake...${RC}"
	if ! command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" install -y handbrake
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter handbrake
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive fr.handbrake.ghb
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Handbrake is already installed.${RC}"
	fi
}

uninstallHandbrake() {
	printf "%b\n" "${YELLOW}Uninstalling Handbrake...${RC}"
	if command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y handbrake
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter handbrake
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive fr.handbrake.ghb
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Handbrake is not installed.${RC}"
	fi
}

main() {
    installHandbrake
}
checkEnv
main