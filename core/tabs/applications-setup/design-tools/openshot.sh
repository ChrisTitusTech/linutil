#!/usr/bin/env bash

. ../../common-script.sh

installOpenshot() {
	printf "%b\n" "${YELLOW}Installing OpenShot...${RC}"
	if ! command_exists openshot; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y openshot-qt
	            ;;
	        pacman)
			    if command_exists yay; then
		        	"$AUR_HELPER" -S --needed --noconfirm openshot
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm openshot
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.openshot.OpenShot
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OpenShot is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installOpenshot