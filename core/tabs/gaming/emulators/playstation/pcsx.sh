#!/bin/sh -e

. ../../../common-script.sh

installPCSX() {
	printf "%b\n" "${YELLOW}Installing PCSX...${RC}"
	if ! command_exists pcsxr; then
	    case "$PACKAGER" in
	    	apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y pcsxr
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter pcsxr
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}PCSX is already installed.${RC}"
	fi
}

uninstallPCSX() {
	printf "%b\n" "${YELLOW}Uninstalling PCSX...${RC}"
	if command_exists pcsxr; then
	    case "$PACKAGER" in
	    	apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y pcsxr
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter pcsxr
	            ;;
	        *)
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}PCSX is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall PCSX${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installPCSX ;;
        2) uninstallPCSX ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main