#!/bin/sh -e

. ../../common-script.sh

installSynfigStudio() {
	printf "%b\n" "${YELLOW}Installing Synfig Studio...${RC}"
	if ! command_exists synfigstudio; then
	    case "$PACKAGER" in
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y synfigstudio
	        	;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm synfigstudio
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm synfigstudio
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.synfig.SynfigStudio
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Synfig Studio is already installed.${RC}"
	fi
}

uninstallSynfigStudio() {
	printf "%b\n" "${YELLOW}Uninstalling Synfig Studio...${RC}"
	if command_exists synfigstudio; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y synfigstudio
	            ;;
	        pacman)
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm synfigstudio
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm synfigstudio
				fi
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.synfig.SynfigStudio
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Synfig Studio is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Synfig Studio${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installSynfigStudio ;;
        2) uninstallSynfigStudio ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main