#!/bin/sh -e

. ../../../common-script.sh

installmupen64plus() {
	printf "%b\n" "${YELLOW}Installing mupen64plus...${RC}"
	if ! command_exists mupen64plus; then
	    case "$PACKAGER" in
	        apt-get|nala)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y mupen64plus-qt
	        	;;
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y mupen64plus
	        	;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter mupen64plus
	            ;;
	        *)
	        	printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}mupen64plus is already installed.${RC}"
	fi
}

uninstallmupen64plus() {
	printf "%b\n" "${YELLOW}Uninstalling mupen64plus...${RC}"
	if command_exists mupen64plus; then
	    case "$PACKAGER" in
	    	apt-get|nala)
	        	"$ESCALATION_TOOL" "$PACKAGER" uninstall -y mupen64plus-qt
	        	;;
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" uninstall -y mupen64plus
	        	;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter mupen64plus
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}mupen64plus is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall mupen64plus${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installmupen64plus ;;
        2) uninstallmupen64plus ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main