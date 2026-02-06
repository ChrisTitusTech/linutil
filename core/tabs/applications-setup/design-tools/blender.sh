#!/bin/sh -e

. ../../common-script.sh

installBlender() {
	printf "%b\n" "${YELLOW}Installing Blender...${RC}"
	if ! flatpak_app_installed org.blender.Blender && ! command_exists blender; then
	    if try_flatpak_install org.blender.Blender; then
	        return 0
	    fi
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y blender
	            ;;
	        pacman)
		        "$AUR_HELPER" -S --needed --noconfirm --cleanafter blender
	            ;;
	        *)
	        	printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
	        	exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is already installed.${RC}"
	fi
}

uninstallBlender() {
	printf "%b\n" "${YELLOW}Uninstalling Blender...${RC}"
	if uninstall_flatpak_if_installed org.blender.Blender; then
	    return 0
	fi
	if command_exists blender; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y blender
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter blender
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Blender${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installBender ;;
        2) uninstallBlender ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
