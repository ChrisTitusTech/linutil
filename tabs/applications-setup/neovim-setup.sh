#!/bin/sh -e

. ../common-script.sh

gitpath="$HOME/.local/share/neovim"

cloneNeovim() {
    # Check if the dir exists before attempting to clone into it.
    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi
    mkdir -p "$HOME/.local/share" # Only create the dir if it doesn't exist.
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/neovim.git "$HOME/.local/share/neovim"
}

setupNeovim() {
    echo "Install Neovim if not already installed"
    case "$PACKAGER" in
        pacman)
            $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm neovim ripgrep fzf python-virtualenv luarocks go shellcheck
            ;;
        apt)
            $ESCALATION_TOOL "$PACKAGER" install -y neovim ripgrep fd-find python3-venv luarocks golang-go shellcheck
            ;;
        dnf)
            $ESCALATION_TOOL "$PACKAGER" install -y neovim ripgrep fzf python3-virtualenv luarocks golang ShellCheck
            ;;
        zypper)
            $ESCALATION_TOOL "$PACKAGER" install -y neovim ripgrep fzf python3-virtualenv luarocks golang ShellCheck
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}" # The packages above were grabbed out of the original nvim-setup-script.
            exit 1
            ;;
    esac
}

backupNeovimConfig() {
    if [ -d "$HOME/.config/nvim" ] && [ ! -d "$HOME/.config/nvim-backup" ]; then
        cp -r "$HOME/.config/nvim" "$HOME/.config/nvim-backup"
    fi
    rm -rf "$HOME/.config/nvim"
}

linkNeovimConfig() {
    mkdir -p "$HOME/.config/nvim"
    ln -s "$gitpath/titus-kickstart/"* "$HOME/.config/nvim/" # Wild card is used here to link all contents of titus-kickstart.
}

revertNeovimSetup() {
    OLD_CONFIG="$HOME/.config/nvim-backup"

    if [ ! -d "$OLD_CONFIG" ]; then
        printf "%b\n" "${RED}Backup not found. Failed to revert changes.${RC}"
        exit 1
    fi

    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi

    printf "%b\n" "${YELLOW}Removing created nvim files${RC}"
    if ! rm -rf "$HOME/.config/nvim"; then
        printf "%b\n" "${RED}Failed to remove $HOME/.config/nvim${RC}"
    fi

    printf "%b\n" "${YELLOW}Moving back old config files to $HOME/.config/nvim${RC}"
    if ! mv "$OLD_CONFIG" "$HOME/.config/nvim"; then
        printf "%b\n" "${RED}Can't move config files!${RC}"
        exit 1
    fi

    printf "%b\n" "${GREEN}Done! restart your shell to see the changes.${RC}"
}

run() {
    checkEnv
    checkEscalationTool
    cloneNeovim
    setupNeovim
    backupNeovimConfig
    linkNeovimConfig
}

revert() {
    checkEnv
    checkEscalationTool
    revertNeovimSetup
}