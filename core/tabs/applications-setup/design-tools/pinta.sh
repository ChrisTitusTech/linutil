#!/usr/bin/env bash

. ../../common-script.sh

installPinta() {
	printf "%b\n" "${YELLOW}Installing Pinta...${RC}"
	if ! command_exists mypaint; then
	    case "$PACKAGER" in
	        dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y pinta
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm pinta
	        	;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive com.github.PintaProject.Pinta
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Pinta is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installPinta