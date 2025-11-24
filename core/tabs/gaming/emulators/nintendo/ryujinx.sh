#!/bin/sh -e

. ../../../common-script.sh

installRyujinx() {
	printf "%b\n" "${YELLOW}Installing Ryujinx...${RC}"
	if ! command_exists ryujinx; then
	    case "$PACKAGER" in
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter ryujinx
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive io.github.ryubing.Ryujinx
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ryujinx is already installed.${RC}"
	fi
}

uninstallRyujinx() {
	printf "%b\n" "${YELLOW}Uninstalling Ryujinx...${RC}"
	if command_exists ryujinx; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter ryujinx
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive io.github.ryubing.Ryujinx
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ryujinx is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Ryujinx${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installRyujinx ;;
        2) uninstallRyujinx ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main