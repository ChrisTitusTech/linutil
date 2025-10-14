#!/bin/sh -e

. ../../common-script.sh

installArdour() {
	printf "%b\n" "${YELLOW}Installing Ardour...${RC}"
	if ! command_exists ardour; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y ardour
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm ardour
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ardour
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.ardour.Ardour
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ardour is already installed.${RC}"
	fi
}

uninstallArdour() {
	printf "%b\n" "${YELLOW}Uninstalling Ardour...${RC}"
	if command_exists ardour; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y ardour
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm ardour
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm ardour
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.ardour.Ardour
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