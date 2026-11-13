#!/bin/sh -e

. ../../common-script.sh

installDarktable() {
	printf "%b\n" "${YELLOW}Installing Darktable...${RC}"
	if ! command_exists darktable; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y darktable
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter darktable
	            ;;
	        *)
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.darktable.Darktable
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Darktable is already installed.${RC}"
	fi
}

uninstallDarktable() {
	printf "%b\n" "${YELLOW}Uninstalling Darktable...${RC}"
	if command_exists darktable; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y darktable
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter darktable
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.darktable.Darktable
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}darktable is not installed.${RC}"
	fi
}

main() {
    installDarktable
}

checkEnv
main