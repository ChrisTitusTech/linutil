#!/bin/sh -e

. ../../common-script.sh

installInkscape() {
	printf "%b\n" "${YELLOW}Installing Inkscape...${RC}"
	if ! command_exists inkscape; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y inkscape
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter inkscape
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.inkscape.Inkscape
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Inkscape is already installed.${RC}"
	fi
}

uninstallInkscape() {
	printf "%b\n" "${YELLOW}Uninstalling Inkscape...${RC}"
	if command_exists inkscape; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y inkscape
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter inkscape
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.inkscape.Inkscape
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Inkscape is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall Inkscape" installInkscape uninstallInkscape
}

checkEnv
main
