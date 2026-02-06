#!/bin/sh -e

. ../../common-script.sh

installGIMP() {
	printf "%b\n" "${YELLOW}Installing GIMP...${RC}"
	if ! flatpak_app_installed org.gimp.GIMP && ! command_exists gimp; then
	    if try_flatpak_install org.gimp.GIMP; then
	        return 0
	    fi
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y gimp
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter gimp
	            ;;
	        *)
	        	printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
	        	exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is already installed.${RC}"
	fi
}

uninstallGIMP() {
	printf "%b\n" "${YELLOW}Uninstalling GIMP...${RC}"
	if uninstall_flatpak_if_installed org.gimp.GIMP; then
	    return 0
	fi
	if command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y gimp
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter gimp
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall GIMP${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installGIMP ;;
        2) uninstallGIMP ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
