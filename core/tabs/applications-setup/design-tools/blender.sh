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
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.blender.Blender
	            fi
	            exit 1
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
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall Blender" installBender uninstallBlender
}

checkEnv
main
