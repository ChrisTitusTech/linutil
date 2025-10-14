#!/usr/bin/env bash

. ../../common-script.sh

installScribus() {
	printf "%b\n" "${YELLOW}Installing Scribus...${RC}"
	if ! command_exists scribus; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y scribus
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm scribus
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm scribus
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive net.scribus.Scribus
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Scribus is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installScribus