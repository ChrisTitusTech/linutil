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
	run_install_uninstall_menu "Do you want to Install or Uninstall Natron (Flatpak)" installNatron uninstallNatron
}

checkEnv
main
