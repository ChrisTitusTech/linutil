#!/bin/sh -e

. ../../common-script.sh

installArdour() {
	printf "%b\n" "${YELLOW}Installing Ardour...${RC}"
	if ! flatpak_app_installed org.ardour.Ardour && ! command_exists ardour; then
	    if try_flatpak_install org.ardour.Ardour; then
	        return 0
	    fi
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y ardour
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter ardour
	            ;;
	        *)
	        	printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
	        	exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ardour is already installed.${RC}"
	fi
}

uninstallArdour() {
	printf "%b\n" "${YELLOW}Uninstalling Ardour...${RC}"
	if uninstall_flatpak_if_installed org.ardour.Ardour; then
	    return 0
	fi
	if command_exists ardour; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y ardour
	            ;;
	        pacman)
		       	"$AUR_HELPER" -R --noconfirm --cleanafter ardour
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ardour is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Ardour${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installArdour ;;
        2) uninstallArdour ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
