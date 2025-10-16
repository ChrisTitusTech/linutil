#!/bin/sh -e

. ../../common-script.sh

installScribus() {
	printf "%b\n" "${YELLOW}Installing Scribus...${RC}"
	if ! command_exists scribus; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y scribus
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm scribus
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm scribus
				fi
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive net.scribus.Scribus
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Scribus is already installed.${RC}"
	fi
}

uninstallScribus() {
	printf "%b\n" "${YELLOW}Uninstalling Scribus...${RC}"
	if command_exists scribus; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y scribus
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm scribus
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm scribus
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive net.scribus.Scribus
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Scribus is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Scribus${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installScribus ;;
        2) uninstallScribus ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main