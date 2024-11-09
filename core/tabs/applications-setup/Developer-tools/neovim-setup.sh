#!/bin/sh -e

. ../../common-script.sh

gitpath="$HOME/.local/share/neovim"

cloneNeovim() {
    # Check if the dir exists before attempting to clone into it.
    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi
    mkdir -p "$HOME/.local/share" # Only create the dir if it doesn't exist.
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/neovim.git "$HOME/.local/share/neovim"
}

installNeovim() {
    if ! command_exists neovim ripgrep git fzf; then
    printf "%b\n" "${YELLOW}Installing Neovim...${RC}"
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
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add neovim ripgrep fzf py3-virtualenv luarocks go shellcheck git
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
    fi
}

backupNeovimConfig() {
    printf "%b\n" "${YELLOW}Backing up existing configuration files...${RC}"
    if [ -d "$HOME/.config/nvim" ] && [ ! -d "$HOME/.config/nvim-backup" ]; then
        cp -r "$HOME/.config/nvim" "$HOME/.config/nvim-backup"
    fi
    rm -rf "$HOME/.config/nvim"
}

linkNeovimConfig() {
    printf "%b\n" "${YELLOW}Linking Neovim configuration files...${RC}"
    mkdir -p "$HOME/.config/nvim"
    ln -s "$gitpath/titus-kickstart/"* "$HOME/.config/nvim/" # Wild card is used here to link all contents of titus-kickstart.
}

checkEnv
checkEscalationTool
installNeovim
cloneNeovim
backupNeovimConfig
linkNeovimConfig
