#!/bin/sh -e

# Include common functions if any
. ../../common-script.sh

gitpath="$HOME/.local/share/neovim"

uninstallNeovim() {
    # Remove Neovim binary and dependencies
    if command_exists nvim; then
        printf "%b\n" "${YELLOW}Uninstalling Neovim and dependencies...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -Rns --noconfirm neovim ripgrep  python-virtualenv luarocks go shellcheck
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y ripgrep fd-find python3-venv luarocks golang-go shellcheck
                [ -f /usr/local/bin/nvim ] && "$ESCALATION_TOOL" rm /usr/local/bin/nvim
                ;;
            dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y neovim ripgrep  python3-virtualenv luarocks golang ShellCheck
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    fi
}

removeNeovimConfig() {
    printf "%b\n" "${YELLOW}Removing Neovim configuration files...${RC}"
    rm -rf "$HOME/.config/nvim"
    
    # Optionally restore backup if it exists
    if [ -d "$HOME/.config/nvim-backup" ]; then
        printf "%b\n" "${YELLOW}Restoring backup Neovim configuration...${RC}"
        mv "$HOME/.config/nvim-backup" "$HOME/.config/nvim"
    fi
}

removeClonedRepo() {
    printf "%b\n" "${YELLOW}Removing cloned Neovim configuration repository...${RC}"
    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi
}

# Check environment and privileges
checkEnv
checkEscalationTool
uninstallNeovim
removeNeovimConfig
removeClonedRepo
