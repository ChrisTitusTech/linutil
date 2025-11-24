#!/bin/sh -e

. ../../../common-script.sh

installblastem() {
	printf "%b\n" "${YELLOW}Installing blastem...${RC}"
	if ! command_exists blastem; then
	    case "$PACKAGER" in
	        apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y blastem
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter blastem
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive com.retrodev.blastem
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}blastem is already installed.${RC}"
	fi
}

uninstallblastem() {
	printf "%b\n" "${YELLOW}Uninstalling blastem...${RC}"
	if command_exists blastem; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y blastem
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter blastem
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive com.retrodev.blastem
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}blastem is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall blastem${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installblastem ;;
        2) uninstallblastem ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main