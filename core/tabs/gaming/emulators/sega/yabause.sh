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
	run_install_uninstall_menu "Do you want to Install or Uninstall yabause" installyabause uninstallyabause
}

checkEnv
main
