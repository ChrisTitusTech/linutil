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
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter synfigstudio
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.synfig.SynfigStudio
	            fi
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
			    "$AUR_HELPER" -R --noconfirm --cleanafter synfigstudio
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
	run_install_uninstall_menu "Do you want to Install or Uninstall Synfig Studio" installSynfigStudio uninstallSynfigStudio
}

checkEnv
main
