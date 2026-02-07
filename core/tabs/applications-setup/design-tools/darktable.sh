#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.darktable.Darktable"
APP_UNINSTALL_PKGS="darktable"


installDarktable() {
	printf "%b\n" "${YELLOW}Installing Darktable...${RC}"
	if ! flatpak_app_installed org.darktable.Darktable && ! command_exists darktable; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y darktable
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter darktable
	            ;;
	        *)
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists darktable; then
            return 0
        fi
        if try_flatpak_install org.darktable.Darktable; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}Darktable is already installed.${RC}"
	fi
}

uninstallDarktable() {
	printf "%b\n" "${YELLOW}Uninstalling Darktable...${RC}"
	if uninstall_flatpak_if_installed org.darktable.Darktable; then
	    return 0
	fi
	if command_exists darktable; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y darktable
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter darktable
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}darktable is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Darktable${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installDarktable ;;
        2) uninstallDarktable ;;
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
