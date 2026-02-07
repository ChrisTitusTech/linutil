#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.openshot.OpenShot"
APP_UNINSTALL_PKGS="openshot-qt"


installOpenShot() {
	printf "%b\n" "${YELLOW}Installing OpenShot...${RC}"
	if ! flatpak_app_installed org.openshot.OpenShot && ! command_exists openshot; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y openshot-qt
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter openshot
	            ;;
	        *)
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists openshot; then
            return 0
        fi
        if try_flatpak_install org.openshot.OpenShot; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}OpenShot is already installed.${RC}"
	fi
}

uninstallOpenShot() {
	printf "%b\n" "${YELLOW}Uninstalling OpenShot...${RC}"
	if uninstall_flatpak_if_installed org.openshot.OpenShot; then
	    return 0
	fi
	if command_exists openshot; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y openshot
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter openshot
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OpenShot is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall OpenShot${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installOpenShot ;;
        2) uninstallOpenShot ;;
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
