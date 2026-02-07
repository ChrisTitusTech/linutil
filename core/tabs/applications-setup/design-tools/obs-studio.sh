#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.obsproject.Studio"
APP_UNINSTALL_PKGS="kmod-v4l2loopback obs-studio v4l2loopback-dkms"


installObsStudio() {
	printf "%b\n" "${YELLOW}Installing OBS Studio...${RC}"
	if ! flatpak_app_installed com.obsproject.Studio && ! command_exists obs-studio; then
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
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists obs-studio; then
            return 0
        fi
        if try_flatpak_install com.obsproject.Studio; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}OBS Studio is already installed.${RC}"
	fi
}

uninstallObsStudio() {
	printf "%b\n" "${YELLOW}Uninstalling OBS Studio...${RC}"
	if uninstall_flatpak_if_installed com.obsproject.Studio; then
	    return 0
	fi
	if command_exists obs-studio; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y obs-studio
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter obs-studio
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
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
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


main
