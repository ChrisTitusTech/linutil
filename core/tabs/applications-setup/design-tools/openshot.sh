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
	        	checkFlatpak
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.openshot.OpenShot
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
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OpenShot is not installed.${RC}"
	fi
}

main() {
    installOpenShot
}

checkEnv
main