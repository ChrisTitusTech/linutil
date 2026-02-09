#!/bin/sh -e

. ../../common-script.sh

installGuix() {
    printf "%b\n" "${YELLOW}Installing GNU Guix package manager...${RC}"
    printf "%b\n" "${CYAN}Guix is a functional package manager with Scheme-based configuration.${RC}"

    if command_exists guix; then
        printf "%b\n" "${GREEN}Guix is already installed.${RC}"
        guix --version
        return 0
    fi

    printf "%b\n" "${YELLOW}Downloading Guix installer...${RC}"
    cd /tmp || exit 1
    curl -LO https://guix.gnu.org/install.sh
    chmod +x install.sh

    printf "%b\n" "${YELLOW}Running Guix installer (requires root)...${RC}"
    "$ESCALATION_TOOL" ./install.sh
    rm -f install.sh

    printf "%b\n" "${GREEN}Guix installed successfully.${RC}"
    printf "%b\n" "${CYAN}Run 'guix pull' to update package definitions.${RC}"
}

checkEnv
checkEscalationTool
checkCommandRequirements "curl"
installGuix
