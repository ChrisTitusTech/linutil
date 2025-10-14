#!/usr/bin/env bash

. ../../common-script.sh

installNatron() {
	printf "%b\n" "${YELLOW}Installing Natron...${RC}"
	if ! command_exists natron; then
		"$ESCALATION_TOOL" flatpak install --noninteractive fr.natron.natron
	else
		printf "%b\n" "${GREEN}Natron is already installed.${RC}"
	fi
}

checkEnv
checkEscalationTool
installNatron