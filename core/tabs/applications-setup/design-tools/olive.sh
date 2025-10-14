#!/bin/sh -e

. ../../common-script.sh

installOlive() {
	printf "%b\n" "${YELLOW}Installing Olive Video Editor...${RC}"
	if ! command_exists olive; then
	    case "$PACKAGER" in
	        dnf)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y olive
	            ;;
	        pacman)
	        	if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm olive
		        else
				    "$ESCALATION_TOOL" flatpak install --noninteractive org.olivevideoeditor.Olive
				fi
	        	;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.olivevideoeditor.Olive
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Olive Video Editor is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installOlive