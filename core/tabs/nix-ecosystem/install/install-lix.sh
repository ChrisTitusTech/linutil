#!/bin/sh -e

. ../../common-script.sh

installLix() {
    printf "%b\n" "${YELLOW}Installing Lix...${RC}"
    printf "%b\n" "${CYAN}Lix is a community fork of Nix focused on stability and UX improvements.${RC}"

    if command_exists nix; then
        printf "%b\n" "${RED}Nix is already installed.${RC}"
        printf "%b\n" "${YELLOW}Use 'Upgrade Nix to Lix' option instead.${RC}"
        return 1
    fi

    printf "%b\n" "${YELLOW}Downloading and running Lix installer...${RC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.lix.systems/lix | sh -s -- install

    printf "%b\n" "${GREEN}Lix installed successfully.${RC}"
    printf "%b\n" "${CYAN}Restart your shell to use Lix.${RC}"
}

checkArch
checkEscalationTool
checkCommandRequirements "curl"
installLix
