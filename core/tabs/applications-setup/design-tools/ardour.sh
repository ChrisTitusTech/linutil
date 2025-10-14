#!/usr/bin/env bash

. ../../common-script.sh

installArdour() {
	printf "%b\n" "${YELLOW}Installing Ardour...${RC}"
	if ! command_exists ardour; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y ardour
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm ardour
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ardour
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.ardour.Ardour
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ardour is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installArdour