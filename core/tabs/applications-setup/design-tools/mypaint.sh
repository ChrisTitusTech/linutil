#!/bin/sh -e

. ../../common-script.sh

installMyPaint() {
	printf "%b\n" "${YELLOW}Installing MyPaint...${RC}"
	if ! command_exists mypaint; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y mypaint
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter mypaint
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.mypaint.MyPaint
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MyPaint is already installed.${RC}"
	fi
}

uninstallMyPaint() {
	printf "%b\n" "${YELLOW}Uninstalling MyPaint...${RC}"
	if command_exists mypaint; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y mypaint
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter mypaint
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.mypaint.mypaint
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MyPaint is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall MyPaint" installMyPaint uninstallMyPaint
}

checkEnv
main
