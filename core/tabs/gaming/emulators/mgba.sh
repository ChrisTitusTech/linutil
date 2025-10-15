#!/bin/sh -e

. ../../common-script.sh

installmGBA() {
	printf "%b\n" "${YELLOW}Installing mGBA...${RC}"
	if ! command_exists mgba; then
	    case "$PACKAGER" in
	        apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y mgba-sdl
	            ;;
	        pacman)
	        	if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm mgba-sdl
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm mgba-sdl
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive io.mgba.mGBA
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
				"$ESCALATION_TOOL" "$PACKAGER" remove -y mgba-sdl
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm mgba-sdl
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm mgba-sdl
				fi
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