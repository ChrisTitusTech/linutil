#!/bin/sh -e

. ../../common-script.sh

installDarktable() {
	printf "%b\n" "${YELLOW}Installing Darktable...${RC}"
	if ! command_exists darktable; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y darktable
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm darktable
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm darktable
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.darktable.Darktable
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Darktable is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installDarktable