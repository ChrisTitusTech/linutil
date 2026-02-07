#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.audacityteam.Audacity"
APP_UNINSTALL_PKGS="audacity"


installAudacity() {
	printf "%b\n" "${YELLOW}Installing Audacity...${RC}"
	if ! flatpak_app_installed org.audacityteam.Audacity && ! command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y audacity
	            ;;
	        pacman)
				"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm --cleanafter audacity
	            ;;
	        *)
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists audacity; then
            return 0
        fi
        if try_flatpak_install org.audacityteam.Audacity; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}Audacity is already installed.${RC}"
	fi
}

uninstallAudacity() {
	printf "%b\n" "${YELLOW}Uninstalling Audacity...${RC}"
	if uninstall_flatpak_if_installed org.audacityteam.Audacity; then
	    return 0
	fi
	if command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y audacity
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter audacity
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Audacity${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installAudacity ;;
        2) uninstallAudacity ;;
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
