#!/bin/sh -e

. ../../common-script.sh

installOpenShot() {
	printf "%b\n" "${YELLOW}Installing OpenShot...${RC}"
	if ! command_exists openshot; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y openshot-qt
	            ;;
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter openshot
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.openshot.OpenShot
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OpenShot is already installed.${RC}"
	fi
}

uninstallOpenShot() {
	printf "%b\n" "${YELLOW}Uninstalling OpenShot...${RC}"
	if command_exists openshot; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y openshot
	            ;;
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter openshot
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.openshot.OpenShot
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OpenShot is not installed.${RC}"
	fi
}

main() {
	run_install_uninstall_menu "Do you want to Install or Uninstall OpenShot" installOpenShot uninstallOpenShot
}

checkEnv
main
