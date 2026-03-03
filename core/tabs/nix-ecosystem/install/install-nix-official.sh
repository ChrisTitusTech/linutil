#!/bin/sh -e

. ../../common-script.sh

installNixOfficial() {
    printf "%b\n" "${YELLOW}Installing Nix via official installer (multi-user daemon)...${RC}"

    if command_exists nix; then
        printf "%b\n" "${GREEN}Nix is already installed.${RC}"
        nix --version
        return 0
    fi

    printf "%b\n" "${YELLOW}Downloading official Nix installer...${RC}"
    curl -L -o /tmp/nix-install.sh https://nixos.org/nix/install
    chmod +x /tmp/nix-install.sh

    printf "%b\n" "${YELLOW}Running installer (multi-user daemon mode)...${RC}"
    /tmp/nix-install.sh --daemon
    rm -f /tmp/nix-install.sh

    printf "%b\n" "${GREEN}Nix installed successfully.${RC}"
    printf "%b\n" "${CYAN}Restart your shell or run: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh${RC}"
}

checkArch
checkEscalationTool
checkCommandRequirements "curl"
installNixOfficial
