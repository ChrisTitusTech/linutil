#!/usr/bin/env bash

. ../../common-script.sh

installMyPaint() {
	printf "%b\n" "${YELLOW}Installing MyPaint...${RC}"
	if ! command_exists mypaint; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y mypaint
	            ;;
	        pacman)
			    if command_exists yay; then
		        	"$AUR_HELPER" -S --needed --noconfirm mypaint
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm mypaint
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.mypaint.MyPaint
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MyPaint is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installMyPaint