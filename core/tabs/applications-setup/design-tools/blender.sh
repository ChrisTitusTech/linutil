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