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
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Inkscape${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installInkscape ;;
        2) uninstallInkscape ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main