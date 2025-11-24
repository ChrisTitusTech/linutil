#!/bin/sh -e

. ../../common-script.sh

installHandbrake() {
	printf "%b\n" "${YELLOW}Installing Handbrake...${RC}"
	if ! command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" install -y handbrake
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter handbrake
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive fr.handbrake.ghb
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Handbrake is already installed.${RC}"
	fi
}

uninstallHandbrake() {
	printf "%b\n" "${YELLOW}Uninstalling Handbrake...${RC}"
	if command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y handbrake
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter handbrake
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive fr.handbrake.ghb
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Handbrake is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Handbrake${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installHandbrake ;;
        2) uninstallHandbrake ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}
checkEnv
checkEscalationTool
main