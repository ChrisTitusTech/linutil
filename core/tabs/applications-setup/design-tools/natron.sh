#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="fr.natron.natron"
APP_UNINSTALL_PKGS=""


installNatron() {
	printf "%b\n" "${YELLOW}Installing Natron...${RC}"
	if ! flatpak_app_installed fr.natron.natron && ! command_exists natron; then
		try_flatpak_install fr.natron.natron
	else
		printf "%b\n" "${GREEN}Natron is already installed.${RC}"
	fi
}

uninstallNatron() {
	printf "%b\n" "${YELLOW}Installing Natron...${RC}"
	if uninstall_flatpak_if_installed fr.natron.natron; then
		return 0
	else
		printf "%b\n" "${GREEN}Natron is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Natron (Flatpak)${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installNatron ;;
        2) uninstallNatron ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


main
