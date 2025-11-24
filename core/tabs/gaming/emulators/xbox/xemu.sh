#!/bin/sh -e

. ../../../common-script.sh

installxemu() {
	printf "%b\n" "${YELLOW}Installing xemu...${RC}"
	if ! command_exists xemu; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter xemu-bin
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive app.xemu.xemu
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xemu is already installed.${RC}"
	fi
}

uninstallxemu() {
	printf "%b\n" "${YELLOW}Uninstalling xemu...${RC}"
	if command_exists xemu; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter xemu-bin
	            ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak install --noninteractive app.xemu.xemu
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}xemu is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall xemu${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installxemu ;;
        2) uninstallxemu ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main