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
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter obs-studio
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive com.obsproject.Studio
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OBS Studio is already installed.${RC}"
	fi
}

uninstallObsStudio() {
	printf "%b\n" "${YELLOW}Uninstalling OBS Studio...${RC}"
	if command_exists obs-studio; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y obs-studio
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter obs-studio
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive com.obsproject.Studio
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OBS Studio is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall OBS Studio${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installObsStudio ;;
        2) uninstallObsStudio ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main