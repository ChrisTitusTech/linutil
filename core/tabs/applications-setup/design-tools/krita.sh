#!/usr/bin/env bash

. ../../common-script.sh

installKrita() {
	printf "%b\n" "${YELLOW}Installing Krita...${RC}"
	if ! command_exists krita; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y krita
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm krita
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm krita
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.kde.krita
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Krita is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installKrita