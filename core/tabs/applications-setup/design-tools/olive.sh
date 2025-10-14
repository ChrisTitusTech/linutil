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
	        	if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm olive
		        else
				    "$ESCALATION_TOOL" flatpak install --noninteractive org.olivevideoeditor.Olive
				fi
	        	;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.olivevideoeditor.Olive
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
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm olive
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm olive
				fi
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.olivevideoeditor.Olive
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}olive is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Olive${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installOlive ;;
        2) uninstallOlive ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main