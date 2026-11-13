#!/bin/sh -e

. ../../common-script.sh

installTenacity() {
	printf "%b\n" "${YELLOW}Installing Tenacity...${RC}"
	if ! command_exists tenacity; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter tenacity
	            ;;
	        *)
				checkFlatpak
				"$ESCALATION_TOOL" flatpak install --noninteractive org.tenacityaudio.Tenacity
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Tenacity is already installed.${RC}"
	fi
}

uninstallTenacity() {
	printf "%b\n" "${YELLOW}Uninstalling Tenacity...${RC}"
	if command_exists tenacity; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter tenacity
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.tenacityaudio.Tenacity
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}tenacity is not installed.${RC}"
	fi
}

main() {
    installTenacity
}

checkEnv
main