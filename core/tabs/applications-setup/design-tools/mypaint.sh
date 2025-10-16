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
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm mypaint
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm mypaint
				fi
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
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm mypaint
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm mypaint
				fi
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
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall MyPaint${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installMyPaint ;;
        2) uninstallMyPaint ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main