#!/bin/sh -e

. ../../common-script.sh

installAudacity() {
	printf "%b\n" "${YELLOW}Installing Audacity...${RC}"
	if ! command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y audacity
	            ;;
	        pacman)
				"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm --cleanafter audacity
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.audacityteam.Audacity
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is already installed.${RC}"
	fi
}

uninstallAudacity() {
	printf "%b\n" "${YELLOW}Uninstalling Audacity...${RC}"
	if command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y audacity
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter audacity
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.audacityteam.Audacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall Audacity" installAudacity uninstallAudacity
}

checkEnv
main
