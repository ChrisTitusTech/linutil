#!/usr/bin/env bash

. ../../common-script.sh

installAudacity() {
	printf "%b\n" "${YELLOW}Installing Audacity...${RC}"
	if ! command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y audacity
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm audacity
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm audacity
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.audacityteam.Audacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installAudacity