#!/bin/sh -e

. ../../common-script.sh

installAudacity() {
	printf "%b\n" "${YELLOW}Installing Audacity...${RC}"
	if ! command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y audacity
	            ;;
	        pacman)
				"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm --cleanafter audacity
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.audacityteam.Audacity
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is already installed.${RC}"
	fi
}

uninstallAudacity() {
	printf "%b\n" "${YELLOW}Uninstalling Audacity...${RC}"
	if command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y audacity
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter audacity
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.audacityteam.Audacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Audacity${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installAudacity ;;
        2) uninstallAudacity ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main