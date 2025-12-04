#!/bin/sh -e

. ../../common-script.sh

installKrita() {
	printf "%b\n" "${YELLOW}Installing Krita...${RC}"
	if ! command_exists krita; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y krita
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter krita
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.kde.krita
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Krita is already installed.${RC}"
	fi
}

uninstallKrita() {
	printf "%b\n" "${YELLOW}Uninstalling Krita...${RC}"
	if command_exists krita; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y krita
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter krita
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.kde.krita
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Krita is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Krita${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installKrita ;;
        2) uninstallKrita ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main