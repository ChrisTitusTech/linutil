#!/usr/bin/env bash

. ../../common-script.sh

installTenacity() {
	printf "%b\n" "${YELLOW}Installing Tenacity...${RC}"
	if ! command_exists tenacity; then
	    case "$PACKAGER" in
	        pacman)
			    if command_exists yay; then
		        	"$AUR_HELPER" -S --needed --noconfirm tenacity
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm tenacity
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.tenacityaudio.Tenacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Tenacity is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installTenacity