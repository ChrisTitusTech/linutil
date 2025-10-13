#!/usr/bin/env bash

. ../../common-script.sh

installGIMP() {
	printf "%b\n" "${YELLOW}Installing GIMP...${RC}"
	if ! command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y gimp
	            ;;
	        pacman)
	        	if command_exists yay; then
		        	"$AUR_HELPER" -S --needed --noconfirm pinta
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gimp
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.gimp.GIMP
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installGIMP