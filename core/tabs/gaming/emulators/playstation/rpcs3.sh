#!/bin/sh -e

. ../../../common-script.sh

installrpcs3() {
	printf "%b\n" "${YELLOW}Installing RPCS3...${RC}"
	if ! command_exists rpcs3; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter rpcs3-bin
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive net.rpcs3.RPCS3
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RPCS3 is already installed.${RC}"
	fi
}

uninstallrpcs3() {
	printf "%b\n" "${YELLOW}Uninstalling RPCS3...${RC}"
	if command_exists rpcs3; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter rpcs3-bin
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak install --noninteractive net.rpcs3.RPCS3
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RPCS3 is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall RPCS3${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installrpcs3 ;;
        2) uninstallrpcs3 ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main