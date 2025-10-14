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
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm blender
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm blender
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.blender.Blender
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installBlender