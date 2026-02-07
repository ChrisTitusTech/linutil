#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.synfig.SynfigStudio"
APP_UNINSTALL_PKGS="synfigstudio"


installSynfigStudio() {
	printf "%b\n" "${YELLOW}Installing Synfig Studio...${RC}"
	if ! flatpak_app_installed org.synfig.SynfigStudio && ! command_exists synfigstudio; then
	    case "$PACKAGER" in
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y synfigstudio
	        	;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter synfigstudio
	            ;;
	        *)
	        	printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
	            ;;
	    esac
        if command_exists synfigstudio; then
            return 0
        fi
        if try_flatpak_install org.synfig.SynfigStudio; then
            return 0
        fi
	else
		printf "%b\n" "${GREEN}Synfig Studio is already installed.${RC}"
	fi
}

uninstallSynfigStudio() {
	printf "%b\n" "${YELLOW}Uninstalling Synfig Studio...${RC}"
	if uninstall_flatpak_if_installed org.synfig.SynfigStudio; then
	    return 0
	fi
	if command_exists synfigstudio; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y synfigstudio
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter synfigstudio
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Synfig Studio is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Synfig Studio${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installSynfigStudio ;;
        2) uninstallSynfigStudio ;;
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
