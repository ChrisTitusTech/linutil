#!/bin/sh -e

. ../../common-script.sh

installNatron() {
	printf "%b\n" "${YELLOW}Installing Natron...${RC}"
	if ! command_exists natron && command_exists flatpak; then
		"$ESCALATION_TOOL" flatpak install --noninteractive fr.natron.natron
	else
		printf "%b\n" "${GREEN}Natron is already installed.${RC}"
	fi
}

uninstallNatron() {
	printf "%b\n" "${YELLOW}Installing Natron...${RC}"
	if command_exists natron; then
		"$ESCALATION_TOOL" flatpak uninstall --noninteractive fr.natron.natron
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
main