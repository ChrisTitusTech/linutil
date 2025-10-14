#!/usr/bin/env bash

. ../../common-script.sh

installInkscape() {
	printf "%b\n" "${YELLOW}Installing Inkscape...${RC}"
	if ! command_exists inkscape; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y inkscape
	            ;;
	        pacman)
			    if command_exists yay; then
		        	"$AUR_HELPER" -S --needed --noconfirm inkscape
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm inkscape
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.inkscape.Inkscape
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Inkscape is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installInkscape