#!/bin/sh -e

. ../../common-script.sh

installInkscape() {
	printf "%b\n" "${YELLOW}Installing Inkscape...${RC}"
	if ! flatpak_app_installed org.inkscape.Inkscape && ! command_exists inkscape; then
	    if try_flatpak_install org.inkscape.Inkscape; then
	        return 0
	    fi
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y inkscape
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter inkscape
	            ;;
	        *)
	        	printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
	        	exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Inkscape is already installed.${RC}"
	fi
}

uninstallInkscape() {
	printf "%b\n" "${YELLOW}Uninstalling Inkscape...${RC}"
	if uninstall_flatpak_if_installed org.inkscape.Inkscape; then
	    return 0
	fi
	if command_exists inkscape; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y inkscape
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter inkscape
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
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
