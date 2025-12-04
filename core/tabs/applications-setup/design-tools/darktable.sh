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
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.darktable.Darktable
	            fi
	            exit 1
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
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}darktable is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Darktable${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installDarktable ;;
        2) uninstallDarktable ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main