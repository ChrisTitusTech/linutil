#!/bin/sh -e

. ../../common-script.sh

installBrave() {
    if ! command_exists com.brave.Browser && ! command_exists brave; then
        printf "%b\n" "${YELLOW}Installing Brave...${RC}"
        curl -fsS https://dl.brave.com/install.sh | sh
    else
        printf "%b\n" "${GREEN}Brave Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installBrave