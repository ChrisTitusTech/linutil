#!/bin/sh -e

. ../../common-script.sh

installMyPaint() {
	printf "%b\n" "${YELLOW}Installing MyPaint...${RC}"
	if ! flatpak_app_installed org.mypaint.MyPaint && ! command_exists mypaint; then
	    if try_flatpak_install org.mypaint.MyPaint; then
	        return 0
	    fi
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y mypaint
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter mypaint
	            ;;
	        *)
	        	printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
	        	exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MyPaint is already installed.${RC}"
	fi
}

uninstallMyPaint() {
	printf "%b\n" "${YELLOW}Uninstalling MyPaint...${RC}"
	if uninstall_flatpak_if_installed org.mypaint.MyPaint; then
	    return 0
	fi
	if command_exists mypaint; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y mypaint
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter mypaint
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MyPaint is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall MyPaint${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installMyPaint ;;
        2) uninstallMyPaint ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
