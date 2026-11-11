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
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.DolphinEmu.dolphin-emu
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
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Dolphin is not installed.${RC}"
	fi
}

main() {
    installDolphin
}

checkEnv
main