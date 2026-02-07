#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.github.PintaProject.Pinta"
APP_UNINSTALL_PKGS="pinta"


installPinta() {
	printf "%b\n" "${YELLOW}Installing Pinta...${RC}"
	if ! flatpak_app_installed com.github.PintaProject.Pinta && ! command_exists pinta; then
	    case "$PACKAGER" in
	        dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y pinta
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter pinta
	        	;;
	        *)
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists pinta; then
            return 0
        fi
        if try_flatpak_install com.github.PintaProject.Pinta; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}Pinta is already installed.${RC}"
	fi
}

uninstallPinta() {
	printf "%b\n" "${YELLOW}Uninstalling Pinta...${RC}"
	if uninstall_flatpak_if_installed com.github.PintaProject.Pinta; then
	    return 0
	fi
	if command_exists pinta; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y pinta
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter pinta
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Pinta is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Pinta${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installPinta ;;
        2) uninstallPinta ;;
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
