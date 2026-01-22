#!/bin/sh -e

. ../../../common-script.sh

installflycast() {
	printf "%b\n" "${YELLOW}Installing flycast...${RC}"
	if ! command_exists flycast; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter flycast
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.flycast.Flycast
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}flycast is already installed.${RC}"
	fi
}

uninstallflycast() {
	printf "%b\n" "${YELLOW}Uninstalling flycast...${RC}"
	if command_exists flycast; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter flycast
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak install --noninteractive opp.flycast.Flycast
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}flycast is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall flycast${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installflycast ;;
        2) uninstallflycast ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main