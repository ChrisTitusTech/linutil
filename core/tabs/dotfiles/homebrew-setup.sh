#!/bin/sh -e

. ../common-script.sh

installHomebrew() {
    if command_exists brew; then
        printf "%b\n" "${GREEN}Homebrew is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Homebrew package manager...${RC}"
    
    # Install Homebrew
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        printf "%b\n" "${RED}Homebrew installation failed!${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Homebrew installed successfully.${RC}"
}

configureShellEnv() {
    printf "%b\n" "${YELLOW}Configuring shell environment for Homebrew...${RC}"
    
    # Determine brew path
    BREW_BIN=""
    if command_exists brew; then
        BREW_BIN=$(command -v brew)
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
    else
        printf "%b\n" "${RED}brew binary not found after installation.${RC}"
        return 1
    fi

    # Configure bash
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q 'brew shellenv' "$HOME/.bashrc" 2>/dev/null; then
            # shellcheck disable=SC2016
            printf 'eval "$(%s shellenv)"\n' "$BREW_BIN" >> "$HOME/.bashrc"
            printf "%b\n" "${GREEN}Added Homebrew to ~/.bashrc${RC}"
        fi
    fi

    # Configure fish
    FISH_CONFIG="$HOME/.config/fish/config.fish"
    if [ -d "$HOME/.config/fish" ]; then
        mkdir -p "$HOME/.config/fish"
        if ! grep -q 'brew shellenv' "$FISH_CONFIG" 2>/dev/null; then
            # shellcheck disable=SC2016
            printf 'eval "$(%s shellenv)"\n' "$BREW_BIN" >> "$FISH_CONFIG"
            printf "%b\n" "${GREEN}Added Homebrew to ~/.config/fish/config.fish${RC}"
        fi
    fi

    # Configure zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'brew shellenv' "$HOME/.zshrc" 2>/dev/null; then
            # shellcheck disable=SC2016
            printf 'eval "$(%s shellenv)"\n' "$BREW_BIN" >> "$HOME/.zshrc"
            printf "%b\n" "${GREEN}Added Homebrew to ~/.zshrc${RC}"
        fi
    fi

    # Activate for current session
    eval "$("$BREW_BIN" shellenv)" || true
    
    printf "%b\n" "${GREEN}Homebrew is ready to use!${RC}"
    printf "%b\n" "${CYAN}You may need to restart your shell for changes to take effect.${RC}"
}

checkEnv
installHomebrew
configureShellEnv
