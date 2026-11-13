#!/bin/sh -e

. ../../common-script.sh

installBlender() {
	printf "%b\n" "${YELLOW}Installing Blender...${RC}"
	if ! command_exists blender; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y blender
	            ;;
	        pacman)
		        "$AUR_HELPER" -S --needed --noconfirm --cleanafter blender
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.blender.Blender
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is already installed.${RC}"
	fi
}

uninstallBlender() {
	printf "%b\n" "${YELLOW}Uninstalling Blender...${RC}"
	if command_exists blender; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y blender
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter blender
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.blender.Blender
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is not installed.${RC}"
	fi
}

main() {
    installBlender
}

checkEnv
main
