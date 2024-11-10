#!/bin/sh -e

# Include common functions if any
. ../../common-script.sh

gitpath="$HOME/.local/share/neovim"

cloneNeovim() {
    # Check if the directory exists and remove it if necessary
    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi
    mkdir -p "$HOME/.local/share" # Only create the directory if it doesn't exist
    cd "$HOME" && git clone https://github.com/aarjaycreation/neovim-kickstart-config.git "$gitpath"
}

installNeovim() {
    if ! command_exists nvim || ! command_exists ripgrep || ! command_exists git || ! command_exists fzf; then
        printf "%b\n" "${YELLOW}Installing Neovim and dependencies...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm neovim ripgrep fzf python-virtualenv luarocks go shellcheck git
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ripgrep fd-find python3-venv luarocks golang-go shellcheck git
                curl -sSLo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x /tmp/nvim.appimage
                "$ESCALATION_TOOL" mv /tmp/nvim.appimage /usr/local/bin/nvim
                ;;
            dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y neovim ripgrep fzf python3-virtualenv luarocks golang ShellCheck git
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    fi
}

backupNeovimConfig() {
    printf "%b\n" "${YELLOW}Backing up existing Neovim configuration...${RC}"
    if [ -d "$HOME/.config/nvim" ] && [ ! -d "$HOME/.config/nvim-backup" ]; then
        cp -r "$HOME/.config/nvim" "$HOME/.config/nvim-backup"
    fi
    rm -rf "$HOME/.config/nvim"
}

linkNeovimConfig() {
    printf "%b\n" "${YELLOW}Linking Neovim configuration files...${RC}"
    mkdir -p "$HOME/.config/nvim"
    
    # Link your lua folder and other files in the config directory
    ln -s "$gitpath/lua" "$HOME/.config/nvim/lua"
    ln -s "$gitpath/init.lua" "$HOME/.config/nvim/init.lua"
    ln -s "$gitpath/.stylua.toml" "$HOME/.config/nvim/.stylua.toml"
    ln -s "$gitpath/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
}

# Check environment and privileges
checkEnv
checkEscalationTool
installNeovim
cloneNeovim
backupNeovimConfig
linkNeovimConfig

