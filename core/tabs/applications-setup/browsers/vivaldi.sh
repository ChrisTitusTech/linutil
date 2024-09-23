#!/bin/sh -e

. ../../common-script.sh

if ! command_exists vivaldi; then
    printf "%b\n" "${YELLOW}Installing Vivaldi...${RC}"
    curl -fsSL https://downloads.vivaldi.com/snapshot/install-vivaldi.sh | sh
    if [ $? -eq 0 ]; then
        printf "%b\n" "${GREEN}Vivaldi installed successfully!${RC}"
    else
        printf "%b\n" "${RED}Vivaldi installation failed!${RC}"
    fi
else
    printf "%b\n" "${GREEN}Vivaldi Browser is already installed.${RC}"
fi

checkEnv
checkEscalationTool
