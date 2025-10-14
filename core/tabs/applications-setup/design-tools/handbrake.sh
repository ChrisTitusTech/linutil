#!/usr/bin/env bash

. ../../common-script.sh

installHandbrake() {
	printf "%b\n" "${YELLOW}Installing Handbrake...${RC}"
	if ! command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" install -y handbrake
	            ;;
	        pacman)
			    if command_exists yay; then
		        	"$AUR_HELPER" -S --needed --noconfirm handbrake
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm handbrake
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive fr.handbrake.ghb
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Handbrake is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installHandbrake