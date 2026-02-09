#!/bin/sh -e

. ../../common-script.sh

installHomeManager() {
    printf "%b\n" "${YELLOW}Installing Home Manager...${RC}"
    printf "%b\n" "${CYAN}Home Manager lets you manage user packages and dotfiles declaratively.${RC}"

    if ! command_exists nix; then
        printf "%b\n" "${RED}Nix is required. Install Nix first.${RC}"
        return 1
    fi

    if command_exists home-manager; then
        printf "%b\n" "${GREEN}Home Manager is already installed.${RC}"
        home-manager --version
        return 0
    fi

    printf "%b\n" "${YELLOW}Adding Home Manager channel...${RC}"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update

    printf "%b\n" "${YELLOW}Installing Home Manager...${RC}"
    nix-shell '<home-manager>' -A install

    printf "%b\n" "${GREEN}Home Manager installed successfully.${RC}"
    printf "%b\n" "${CYAN}Edit: ~/.config/home-manager/home.nix${RC}"
    printf "%b\n" "${CYAN}Apply: home-manager switch${RC}"
}

checkEnv
installHomeManager
