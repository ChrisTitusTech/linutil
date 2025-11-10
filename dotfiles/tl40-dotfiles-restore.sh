#!/bin/sh -e

. ../common-script.sh

DOTFILES_REPO="https://github.com/TuxLux40/TL40-Dots.git"
DOTFILES_DIR="$HOME/.dotfiles"

cloneDotfiles() {
    if [ -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${YELLOW}Dotfiles directory already exists at $DOTFILES_DIR${RC}"
        printf "%b" "${GREEN}Would you like to update it? [y/N]: ${RC}"
        read -r response
        
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            printf "%b\n" "${YELLOW}Updating dotfiles repository...${RC}"
            cd "$DOTFILES_DIR" && git pull
        else
            printf "%b\n" "${YELLOW}Skipping clone/update.${RC}"
            return 0
        fi
    else
        printf "%b\n" "${YELLOW}Cloning TL40-Dots dotfiles repository...${RC}"
        if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            printf "%b\n" "${RED}Failed to clone dotfiles repository!${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Dotfiles repository cloned successfully.${RC}"
    fi
}

runDotfilesInstall() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${RED}Dotfiles directory not found. Please clone first.${RC}"
        return 1
    fi

    printf "%b\n" "${YELLOW}Running dotfiles installation script...${RC}"
    printf "%b\n" "${CYAN}This will:${RC}"
    printf "%b\n" "${CYAN}  - Install essential tools (Fish, Atuin, Starship, etc.)${RC}"
    printf "%b\n" "${CYAN}  - Create symlinks to configuration files${RC}"
    printf "%b\n" "${CYAN}  - Set up shell integrations${RC}"
    
    printf "%b" "${GREEN}Do you want to proceed? [y/N]: ${RC}"
    read -r response
    
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd "$DOTFILES_DIR"
        if [ -f "./install.sh" ]; then
            sh ./install.sh
        else
            printf "%b\n" "${RED}Installation script not found in dotfiles repository!${RC}"
            return 1
        fi
    else
        printf "%b\n" "${YELLOW}Installation cancelled.${RC}"
    fi
}

symlinkDotfiles() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${RED}Dotfiles directory not found. Please clone first.${RC}"
        return 1
    fi

    printf "%b\n" "${YELLOW}Creating symlinks for dotfiles...${RC}"
    
    if [ -f "$DOTFILES_DIR/scripts/postinstall/dotfile-symlinks.sh" ]; then
        cd "$DOTFILES_DIR"
        sh ./scripts/postinstall/dotfile-symlinks.sh
        printf "%b\n" "${GREEN}Dotfiles symlinked successfully.${RC}"
    else
        printf "%b\n" "${RED}Symlink script not found in dotfiles repository!${RC}"
        return 1
    fi
}

showMenu() {
    printf "%b\n" "${CYAN}=== TL40-Dots Dotfiles Manager ===${RC}"
    printf "%b\n" "1) Clone/Update dotfiles repository"
    printf "%b\n" "2) Run full installation (recommended for first time)"
    printf "%b\n" "3) Create symlinks only"
    printf "%b\n" "4) Exit"
    printf "%b" "${GREEN}Enter your choice [1-4]: ${RC}"
    read -r choice
    
    case "$choice" in
        1)
            cloneDotfiles
            ;;
        2)
            cloneDotfiles
            runDotfilesInstall
            ;;
        3)
            symlinkDotfiles
            ;;
        4)
            printf "%b\n" "${GREEN}Exiting...${RC}"
            exit 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice!${RC}"
            exit 1
            ;;
    esac
}

checkEnv
showMenu
