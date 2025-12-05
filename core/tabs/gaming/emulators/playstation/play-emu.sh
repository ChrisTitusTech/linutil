#!/bin/sh -e

. ../../../common-script.sh

installPlay() {
	printf "%b\n" "${YELLOW}Installing Play!...${RC}"
	if ! command_exists play-emu; then
	    case "$PACKAGER" in
	        # pacman)
	        # 	"$AUR_HELPER" -S --needed --noconfirm --cleanafter play-emu
	        #     ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.purei.Play
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Play! is already installed.${RC}"
	fi
}

uninstallPlay() {
	printf "%b\n" "${YELLOW}Uninstalling Play!...${RC}"
	if command_exists play-emu; then
	    case "$PACKAGER" in
	        # pacman)
			#     "$AUR_HELPER" -R --noconfirm --cleanafter play-emu
	        #     ;;
	        *)
	        	"$ESCALATION_TOOL" flatpak uninstall --noninteractive org.purei.Play
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Play! is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Play!${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installPlay ;;
        2) uninstallPlay ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main