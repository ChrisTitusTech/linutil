#!/bin/sh -e

. ../../../common-script.sh

installmGBA() {
	printf "%b\n" "${YELLOW}Installing mGBA...${RC}"
	if ! command_exists mgba; then
	    case "$PACKAGER" in
	        apt-get|nala)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y liblua5.4-dev
			    "$ESCALATION_TOOL" "$PACKAGER" install -y mgba-qt
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter lua
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter mgba-qt
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive io.mgba.mGBA
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}mGBA is already installed.${RC}"
	fi
}

uninstallmGBA() {
	printf "%b\n" "${YELLOW}Uninstalling mGBA...${RC}"
	if command_exists mgba; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y mgba-qt
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter mgba-qt
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive io.mgba.mGBA
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}mGBA is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall mGBA${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installmGBA ;;
        2) uninstallmGBA ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main