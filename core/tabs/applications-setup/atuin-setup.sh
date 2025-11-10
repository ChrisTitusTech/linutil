#!/bin/sh -e

. ../common-script.sh

installAtuin() {
    if command_exists atuin; then
        printf "%b\n" "${GREEN}Atuin is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Atuin (shell history sync tool)...${RC}"
    
    if ! curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
        printf "%b\n" "${RED}Failed to install Atuin!${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Atuin installed successfully.${RC}"
}

importHistory() {
    if ! command_exists atuin; then
        printf "%b\n" "${RED}Atuin is not installed. Please install it first.${RC}"
        return 1
    fi

    printf "%b\n" "${YELLOW}Importing shell history to Atuin...${RC}"
    
    if atuin import auto; then
        printf "%b\n" "${GREEN}Shell history imported successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}History import may have encountered some issues, but Atuin is ready to use.${RC}"
    fi
}

configureShell() {
    printf "%b\n" "${YELLOW}Configuring shell integration...${RC}"
    
    current_shell=$(basename "$SHELL")
    
    case "$current_shell" in
    "bash"|"zsh"|"fish")
        printf "%b\n" "${GREEN}Please restart your shell or source your configuration to enable Atuin.${RC}"
        printf "%b\n" "${CYAN}Atuin provides enhanced shell history with sync capabilities.${RC}"
        ;;
    *)
        printf "%b\n" "${YELLOW}Shell integration for $current_shell may require manual configuration.${RC}"
        printf "%b\n" "${CYAN}See https://atuin.sh for more information.${RC}"
        ;;
    esac
}

checkEnv
checkEscalationTool
installAtuin
importHistory
configureShell
