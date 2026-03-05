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
	run_install_uninstall_menu "Do you want to Install or Uninstall PCSX" installPCSX uninstallPCSX
}

checkEnv
main
