#!/bin/sh -e

. ../../../common-script.sh

installDolphin() {
	printf "%b\n" "${YELLOW}Installing Dolphin...${RC}"
	if ! command_exists dolphin-emu; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y dolphin-emu
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter dolphin-emu
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.DolphinEmu.dolphin-emu
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Dolphin is already installed.${RC}"
	fi
}

uninstallDolphin() {
	printf "%b\n" "${YELLOW}Uninstalling Dolphin...${RC}"
	if command_exists dolphin-emu; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y dolphin-emu
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter dolphin-emu
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.DolphinEmu.dolphin-emu
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Dolphin is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Dolphin${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installDolphin ;;
        2) uninstallDolphin ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main