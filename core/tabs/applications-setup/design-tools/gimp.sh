#!/bin/sh -e

. ../../common-script.sh

installGIMP() {
	printf "%b\n" "${YELLOW}Installing GIMP...${RC}"
	if ! command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y gimp
	            ;;
	        pacman)
	        	if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm gimp
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gimp
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.gimp.GIMP
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is already installed.${RC}"
	fi
}

uninstallGIMP() {
	printf "%b\n" "${YELLOW}Uninstalling GIMP...${RC}"
	if command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y gimp
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm gimp
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm gimp
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.gimp.GIMP
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
