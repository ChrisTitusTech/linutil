#!/bin/sh -e

. ../../../common-script.sh

installbsnes() {
	printf "%b\n" "${YELLOW}Installing bsnes...${RC}"
	if ! command_exists bsnes; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter bsnes-hd
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive dev.bsnes.bsnes
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}bsnes is already installed.${RC}"
	fi
}

uninstallbsnes() {
	printf "%b\n" "${YELLOW}Uninstalling bsnes...${RC}"
	if command_exists bsnes; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter bsnes-hd
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive dev.bsnes.bsnes
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}bsnes is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall bsnes${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installbsnes ;;
        2) uninstallbsnes ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main