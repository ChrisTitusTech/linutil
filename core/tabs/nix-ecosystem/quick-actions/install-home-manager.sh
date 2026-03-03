#!/bin/sh -e

. ../../common-script.sh

installHomeManager() {
    printf "%b\n" "${YELLOW}Installing Home Manager...${RC}"
    printf "%b\n" "${CYAN}Home Manager manages user packages and dotfiles declaratively.${RC}"

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

    printf "%b\n" ""
    printf "%b\n" "${GREEN}✓ Home Manager installed successfully.${RC}"
    printf "%b\n" ""
    
    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════
  USAGE
══════════════════════════════════════════════════════════════
  Default config:   ~/.config/home-manager/home.nix
  Apply changes:    home-manager switch
  List generations: home-manager generations

══════════════════════════════════════════════════════════════
  CUSTOM CONFIG LOCATION
══════════════════════════════════════════════════════════════
  The default path is fine for getting started, but most users
  keep their config in a dotfiles repo. Options:

  Symlink:
    rm -rf ~/.config/home-manager
    ln -s ~/dotfiles/home-manager ~/.config/home-manager

  Flake-based (recommended):
    home-manager switch --flake ~/dotfiles#$USER

  Direct file:
    home-manager -f ~/dotfiles/home.nix switch

══════════════════════════════════════════════════════════════
  TIP: Use 'Scaffold Flake Config' in LinUtil to generate
  a proper Snowfall-style directory structure.
══════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"
}

checkArch
installHomeManager
