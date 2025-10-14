#!/bin/sh -e

. ../../common-script.sh

installObsStudio() {
	printf "%b\n" "${YELLOW}Installing OBS Studio...${RC}"
	if ! command_exists obs-studio; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" install -y v4l2loopback-dkms obs-studio
	            ;;
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install kmod-v4l2loopback
	        	"$ESCALATION_TOOL" "$PACKAGER" install obs-studio
	        	;;
	        pacman)
	        	if command_exists yay || command_exists paru; then
	        		"$AUR_HELPER" -S --needed --noconfirm obs-studio
	        	else
			    	"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm v4l2loopback-dkms obs-studio
			    fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive com.obsproject.Studio
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OBS Studio is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installObsStudio