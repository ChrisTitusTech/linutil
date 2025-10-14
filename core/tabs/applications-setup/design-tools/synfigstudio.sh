#!/bin/sh -e

. ../../common-script.sh

installSynfigStudio() {
	printf "%b\n" "${YELLOW}Installing Synfig Studio...${RC}"
	if ! command_exists synfigstudio; then
	    case "$PACKAGER" in
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y synfigstudio
	        	;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm synfigstudio
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm synfigstudio
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.synfig.SynfigStudio
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Synfig Studio is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installSynfigStudio