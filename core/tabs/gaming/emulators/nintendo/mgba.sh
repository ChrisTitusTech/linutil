#!/bin/sh -e

. ../../../common-script.sh

installmGBA() {
	printf "%b\n" "${YELLOW}Installing mGBA...${RC}"
	if ! command_exists mgba; then
	    case "$PACKAGER" in
	        apt-get|nala)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y liblua5.4-dev
			    "$ESCALATION_TOOL" "$PACKAGER" install -y mgba-qt
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter lua
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter mgba-qt
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive io.mgba.mGBA
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
				"$ESCALATION_TOOL" "$PACKAGER" remove -y mgba-qt
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter mgba-qt
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
    installmGBA
}

checkEnv
main