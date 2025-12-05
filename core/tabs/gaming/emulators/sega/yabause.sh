#!/bin/sh -e

. ../../../common-script.sh

installyabause() {
	printf "%b\n" "${YELLOW}Installing yabause...${RC}"
	if ! command_exists yabause; then
	    case "$PACKAGER" in
	    	apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y yabause
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter cmake3
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter yabause-qt5
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}yabause is already installed.${RC}"
	fi
}

uninstallyabause() {
	printf "%b\n" "${YELLOW}Uninstalling yabause...${RC}"
	if command_exists yabause; then
	    case "$PACKAGER" in
	    	apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y yabause
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter yabause-qt5
	            ;;
	        *)
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}yabause is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall yabause${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installyabause ;;
        2) uninstallyabause ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main