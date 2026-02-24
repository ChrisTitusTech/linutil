#!/bin/sh -e

. ../../common-script.sh

installPinta() {
	printf "%b\n" "${YELLOW}Installing Pinta...${RC}"
	if ! command_exists pinta; then
	    case "$PACKAGER" in
	        dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y pinta
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter pinta
	        	;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive com.github.PintaProject.Pinta
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Pinta is already installed.${RC}"
	fi
}

uninstallPinta() {
	printf "%b\n" "${YELLOW}Uninstalling Pinta...${RC}"
	if command_exists pinta; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y pinta
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter pinta
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive com.github.PintaProject.Pinta
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Pinta is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall Pinta" installPinta uninstallPinta
}

checkEnv
main
