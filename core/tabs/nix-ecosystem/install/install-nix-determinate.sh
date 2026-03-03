#!/bin/sh -e

. ../../common-script.sh

installNixDeterminate() {
    printf "%b\n" "${YELLOW}Installing Nix via Determinate Systems installer...${RC}"
    printf "%b\n" "${CYAN}This installer enables flakes by default and includes an uninstaller.${RC}"

    if command_exists nix; then
        printf "%b\n" "${GREEN}Nix is already installed.${RC}"
        nix --version
        return 0
    fi

    printf "%b\n" "${YELLOW}Downloading and running Determinate installer...${RC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    printf "%b\n" "${GREEN}Nix installed successfully.${RC}"
    printf "%b\n" "${CYAN}Restart your shell or run: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh${RC}"
}

checkArch
checkEscalationTool
checkCommandRequirements "curl"
installNixDeterminate
