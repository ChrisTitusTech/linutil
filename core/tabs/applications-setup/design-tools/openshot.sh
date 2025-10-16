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
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -S --needed --noconfirm openshot
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm openshot
				fi
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
			    if command_exists yay || command_exists paru; then
		        	"$AUR_HELPER" -R --noconfirm openshot
		        else
				    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm openshot
				fi
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
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall OpenShot${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installOpenShot ;;
        2) uninstallOpenShot ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main