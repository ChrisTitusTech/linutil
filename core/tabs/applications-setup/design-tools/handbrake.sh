#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="fr.handbrake.ghb"
APP_UNINSTALL_PKGS="handbrake"


installHandbrake() {
	printf "%b\n" "${YELLOW}Installing Handbrake...${RC}"
	if ! flatpak_app_installed fr.handbrake.ghb && ! command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" install -y handbrake
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter handbrake
	            ;;
	        *)
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists handbrake; then
            return 0
        fi
        if try_flatpak_install fr.handbrake.ghb; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}Handbrake is already installed.${RC}"
	fi
}

uninstallHandbrake() {
	printf "%b\n" "${YELLOW}Uninstalling Handbrake...${RC}"
	if uninstall_flatpak_if_installed fr.handbrake.ghb; then
	    return 0
	fi
	if command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y handbrake
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter handbrake
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
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
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


main
