#!/bin/sh -e

. ../../../common-script.sh

installMelonDS() {
	printf "%b\n" "${YELLOW}Installing MelonDS...${RC}"
	if ! command_exists melonDS; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter melonds-bin
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive net.kuribo64.melonDS
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MelonDS is already installed.${RC}"
	fi
}

uninstallMelonDS() {
	printf "%b\n" "${YELLOW}Uninstalling MelonDS...${RC}"
	if command_exists melonDS; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter melonds-bin
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive net.kuribo64.melonDS
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MelonDS is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall MelonDS${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installMelonDS ;;
        2) uninstallMelonDS ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main