#!/bin/sh -e

. ../../common-script.sh

installTenacity() {
	printf "%b\n" "${YELLOW}Installing Tenacity...${RC}"
	if ! command_exists tenacity; then
	    case "$PACKAGER" in
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm tenacity
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm tenacity
				fi
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.tenacityaudio.Tenacity
	            fi
	            exit 1
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
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y tenacity
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm tenacity
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm tenacity
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.tenacityaudio.Tenacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}tenacity is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Tenacity${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installTenacity ;;
        2) uninstallTenacity ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main