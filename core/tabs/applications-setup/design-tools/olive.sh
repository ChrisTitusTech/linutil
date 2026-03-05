#!/bin/sh -e

. ../../common-script.sh

installOlive() {
	printf "%b\n" "${YELLOW}Installing Olive Video Editor...${RC}"
	if ! command_exists olive; then
	    case "$PACKAGER" in
	        dnf)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y olive
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter olive
	        	;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.olivevideoeditor.Olive
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Olive Video Editor is already installed.${RC}"
	fi
}

uninstallOlive() {
	printf "%b\n" "${YELLOW}Uninstalling Olive...${RC}"
	if command_exists olive; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y olive
	            ;;
	        pacman)
		        "$AUR_HELPER" -R --noconfirm --cleanafter olive
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.olivevideoeditor.Olive
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}olive is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall Olive" installOlive uninstallOlive
}

checkEnv
main
